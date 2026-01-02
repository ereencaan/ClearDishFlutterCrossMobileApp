// Supabase Edge Function: stripe-owner-webhook
//
// Purpose:
// - Receive Stripe webhook events for subscription payments coming from WPForms.
// - Extract restaurant owner identity from Stripe metadata (owner_uid).
// - Update Supabase Auth user's app_metadata:
//   - owner_paid: true
//   - owner_plan: starter | pro | plus (best-effort)
//   - owner_paid_until: ISO datetime (best-effort from Stripe period end)
//
// Required secrets (Supabase Dashboard -> Edge Functions -> Secrets or via CLI):
// - STRIPE_SECRET_KEY
// - STRIPE_WEBHOOK_SECRET
// - SERVICE_ROLE_KEY  (your Supabase "service_role" key)
// Optional:
// - PROJECT_URL (defaults to https://<project-ref>.supabase.co)
// - PRICE_STARTER / PRICE_PRO / PRICE_PLUS (to infer plan from Stripe price.id)

import Stripe from "https://esm.sh/stripe@14.21.0?target=deno&no-check";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.7";

type Meta = Record<string, unknown>;

function toStr(v: unknown): string | undefined {
  if (typeof v === "string") return v;
  if (typeof v === "number") return String(v);
  if (typeof v === "boolean") return v ? "true" : "false";
  return undefined;
}

function getMeta(obj: unknown): Meta {
  if (obj && typeof obj === "object" && "metadata" in obj) {
    const md = (obj as { metadata?: unknown }).metadata;
    if (md && typeof md === "object") return md as Meta;
  }
  return {};
}

function getDescription(obj: unknown): string | undefined {
  if (obj && typeof obj === "object" && "description" in obj) {
    const d = (obj as { description?: unknown }).description;
    if (typeof d === "string" && d.trim().length > 0) return d;
  }
  return undefined;
}

function parseFromDescription(desc?: string): { ownerUid?: string; plan?: string; email?: string } {
  if (!desc) return {};
  // We expect something like:
  // "cleardish owner_uid=<uuid> plan=starter email=test@example.com"
  const ownerUid =
    desc.match(/\bowner_uid\s*[:=]\s*([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})\b/i)?.[1];
  const plan =
    desc.match(/\bplan\s*[:=]\s*(starter|pro|plus)\b/i)?.[1]?.toLowerCase();
  const email =
    desc.match(/\bemail\s*[:=]\s*([^\s|,;]+@[^\s|,;]+)\b/i)?.[1];
  return { ownerUid, plan, email };
}

function inferFromMeta(meta: Meta): { ownerUid?: string; plan?: string; email?: string } {
  const uuidRe = /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/i;
  const emailRe = /[^\s|,;]+@[^\s|,;]+\.[^\s|,;]+/i;
  const plans = new Set(["starter", "pro", "plus"]);

  let ownerUid: string | undefined;
  let plan: string | undefined;
  let email: string | undefined;

  const uuidCandidates: string[] = [];

  for (const [k, v] of Object.entries(meta)) {
    const key = k.toLowerCase();
    const val = toStr(v)?.trim();
    if (!val) continue;

    // collect uuids as candidates
    const uuidMatch = val.match(uuidRe)?.[0];
    if (uuidMatch) {
      uuidCandidates.push(uuidMatch);
      if (!ownerUid && (key.includes("uid") || key.includes("owner"))) {
        ownerUid = uuidMatch;
      }
    }

    if (!plan) {
      const maybePlan = val.toLowerCase();
      if (plans.has(maybePlan)) plan = maybePlan;
    }

    if (!email) {
      const m = val.match(emailRe)?.[0];
      if (m) email = m;
    }
  }

  // If we found exactly one UUID anywhere in metadata, accept it as owner uid.
  if (!ownerUid && uuidCandidates.length === 1) ownerUid = uuidCandidates[0];

  return { ownerUid, plan, email };
}

function addDaysIso(days: number): string {
  const d = new Date();
  d.setDate(d.getDate() + days);
  return d.toISOString();
}

function inferPlanFromPriceId(priceId?: string): string | undefined {
  if (!priceId) return undefined;
  const starter = Deno.env.get("PRICE_STARTER");
  const pro = Deno.env.get("PRICE_PRO");
  const plus = Deno.env.get("PRICE_PLUS");
  if (starter && priceId === starter) return "starter";
  if (pro && priceId === pro) return "pro";
  if (plus && priceId === plus) return "plus";
  // Fallback: infer from common naming conventions (e.g. "starter_1900_monthly")
  const p = priceId.toLowerCase();
  if (p.includes("starter")) return "starter";
  if (p.includes("plus")) return "plus";
  if (p.includes("pro")) return "pro";
  return undefined;
}

function extractEmailFromObj(obj: any): string | undefined {
  const candidates = [
    obj?.customer_email,
    obj?.receipt_email,
    obj?.customer_details?.email,
    obj?.billing_details?.email,
    obj?.charges?.data?.[0]?.billing_details?.email,
  ];
  for (const c of candidates) {
    if (typeof c === "string" && c.includes("@")) return c.trim();
  }
  return undefined;
}

async function resolveOwnerUidByEmail(
  supabaseAdmin: ReturnType<typeof createClient>,
  email?: string,
): Promise<string | undefined> {
  if (!email) return undefined;
  const target = email.trim().toLowerCase();
  // Best-effort: paginate a few pages; most projects will be small.
  for (let page = 1; page <= 10; page++) {
    const { data, error } = await supabaseAdmin.auth.admin.listUsers({
      page,
      perPage: 200,
    });
    if (error) return undefined;
    const users = data?.users ?? [];
    const match = users.find((u) => (u.email ?? "").toLowerCase() === target);
    if (match?.id) return match.id;
    if (users.length < 200) break; // no more pages
  }
  return undefined;
}

async function bestEffortPaidUntil(
  stripe: Stripe,
  obj: any,
): Promise<{ paidUntilIso: string; subscriptionId?: string; customerId?: string; priceId?: string }> {
  // Defaults to "now + 30 days" if we can't read Stripe period end.
  const fallback = { paidUntilIso: addDaysIso(30) };

  try {
    // subscription object (customer.subscription.*)
    if (obj?.object === "subscription" && typeof obj?.current_period_end === "number") {
      return {
        paidUntilIso: new Date(obj.current_period_end * 1000).toISOString(),
        subscriptionId: obj.id,
        customerId: obj.customer,
        priceId: obj?.items?.data?.[0]?.price?.id,
      };
    }

    // checkout.session.completed
    if (obj?.object === "checkout.session") {
      const subId = obj?.subscription;
      const customerId = obj?.customer;
      if (typeof subId === "string" && subId.length > 0) {
        const sub = await stripe.subscriptions.retrieve(subId);
        const periodEnd = sub?.current_period_end;
        if (typeof periodEnd === "number") {
          return {
            paidUntilIso: new Date(periodEnd * 1000).toISOString(),
            subscriptionId: subId,
            customerId: toStr(customerId),
            priceId: sub?.items?.data?.[0]?.price?.id,
          };
        }
      }
      return { ...fallback, subscriptionId: toStr(subId), customerId: toStr(customerId) };
    }

    // invoice.payment_succeeded
    if (obj?.object === "invoice") {
      const subId = obj?.subscription;
      const customerId = obj?.customer;
      const line = obj?.lines?.data?.[0];
      const periodEnd = line?.period?.end;
      if (typeof periodEnd === "number") {
        return {
          paidUntilIso: new Date(periodEnd * 1000).toISOString(),
          subscriptionId: toStr(subId),
          customerId: toStr(customerId),
          priceId: line?.price?.id,
        };
      }
      return { ...fallback, subscriptionId: toStr(subId), customerId: toStr(customerId) };
    }

    // invoice_payment.paid (Stripe "invoice_payment" object)
    if (obj?.object === "invoice_payment") {
      const invoiceId = toStr(obj?.invoice);
      const piId = toStr(obj?.payment?.payment_intent);
      if (invoiceId) {
        const inv = await stripe.invoices.retrieve(invoiceId);
        const line = (inv as any)?.lines?.data?.[0];
        const periodEnd = line?.period?.end ?? (inv as any)?.period_end;
        if (typeof periodEnd === "number") {
          return {
            paidUntilIso: new Date(periodEnd * 1000).toISOString(),
            subscriptionId: toStr((inv as any)?.subscription),
            customerId: toStr((inv as any)?.customer),
            priceId: line?.price?.id,
          };
        }
      }
      // Fallback: we at least keep customer id if present
      return { ...fallback, customerId: toStr(obj?.customer), subscriptionId: undefined, priceId: undefined };
    }

    // payment_intent.succeeded / charge.succeeded
    if (obj?.object === "payment_intent" || obj?.object === "charge") {
      return { ...fallback, customerId: toStr(obj?.customer) };
    }
  } catch (_) {
    // ignore and use fallback
  }

  return fallback;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { status: 200 });
  }

  const stripeSecretKey = Deno.env.get("STRIPE_SECRET_KEY");
  const stripeWebhookSecret = Deno.env.get("STRIPE_WEBHOOK_SECRET");
  const serviceRoleKey = Deno.env.get("SERVICE_ROLE_KEY");

  if (!stripeSecretKey || !stripeWebhookSecret || !serviceRoleKey) {
    return new Response("Missing required secrets.", { status: 500 });
  }

  const supabaseUrl =
    Deno.env.get("PROJECT_URL") ?? "https://uhquiaattcdarsyvogmj.supabase.co";

  const stripe = new Stripe(stripeSecretKey, { apiVersion: "2023-10-16" });
  const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  const sig = req.headers.get("stripe-signature");
  if (!sig) return new Response("Missing Stripe-Signature header.", { status: 400 });

  const rawBody = await req.text();

  let event: Stripe.Event;
  try {
    // In Deno/Edge runtimes, webhook verification must use the async variant.
    // Otherwise you may see: "SubtleCryptoProvider cannot be used in a synchronous context".
    event = await stripe.webhooks.constructEventAsync(rawBody, sig, stripeWebhookSecret);
  } catch (e) {
    return new Response(`Webhook signature verification failed: ${e instanceof Error ? e.message : "unknown"}`, {
      status: 400,
    });
  }

  // Handle a few common events depending on how WPForms is configured.
  const supported = new Set([
    "checkout.session.completed",
    "invoice.payment_succeeded",
    "invoice.paid",
    "invoice_payment.paid",
    "payment_intent.succeeded",
    "charge.succeeded",
    "customer.subscription.created",
    "customer.subscription.updated",
  ]);

  if (!supported.has(event.type)) {
    return new Response("ignored", { status: 200 });
  }

  const obj: any = (event.data as any)?.object;
  const meta = getMeta(obj);
  const desc = getDescription(obj);
  const parsed = parseFromDescription(desc);
  const inferred = inferFromMeta(meta);

  // WPForms custom meta keys (recommended):
  // - owner_uid, plan, email, restaurant_name, address
  const ownerUid =
    toStr(meta["owner_uid"]) ??
    toStr(meta["uid"]) ??
    parsed.ownerUid ??
    inferred.ownerUid;
  const metaPlan = ((
    toStr(meta["plan"]) ??
    toStr(meta["owner_plan"]) ??
    parsed.plan ??
    inferred.plan ??
    ""
  )).toLowerCase();

  const ownerEmail =
    toStr(meta["email"]) ??
    parsed.email ??
    inferred.email ??
    extractEmailFromObj(obj);

  // If owner_uid is missing, try to resolve by email (emails are unique in Supabase Auth).
  const resolvedOwnerUid =
    ownerUid ?? (await resolveOwnerUidByEmail(supabaseAdmin, ownerEmail));

  if (!resolvedOwnerUid) {
    return new Response(
      "Missing owner identifier (need metadata.owner_uid or resolvable email).",
      { status: 400 },
    );
  }

  const { paidUntilIso, subscriptionId, customerId, priceId } = await bestEffortPaidUntil(
    stripe,
    obj,
  );

  const inferredPlan =
    ["starter", "pro", "plus"].includes(metaPlan) ? metaPlan : inferPlanFromPriceId(priceId);

  const nextMeta: Record<string, unknown> = {
    owner_paid: true,
    owner_paid_until: paidUntilIso,
  };
  if (inferredPlan) nextMeta["owner_plan"] = inferredPlan;
  if (subscriptionId) nextMeta["owner_subscription_id"] = subscriptionId;
  if (customerId) nextMeta["owner_customer_id"] = customerId;

  const { error } = await supabaseAdmin.auth.admin.updateUserById(resolvedOwnerUid, {
    app_metadata: nextMeta,
  });

  if (error) return new Response(`Supabase update failed: ${error.message}`, { status: 500 });
  return new Response("ok", { status: 200 });
});
