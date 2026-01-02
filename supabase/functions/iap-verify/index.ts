// Supabase Edge Function: iap-verify
//
// Purpose:
// - Confirm a mobile in-app purchase (Google Play / App Store) and store the
//   subscription status for the authenticated *user* in `public.user_profiles`.
//
// IMPORTANT:
// - Proper verification requires Google Play Developer API / App Store Server API.
// - To unblock end-to-end testing, this function supports a bypass mode:
//   set secret IAP_BYPASS_VERIFY=true to accept any purchase and grant access.
//
// Required secrets:
// - SERVICE_ROLE_KEY
// Optional:
// - PROJECT_URL (defaults to this project's URL)
// - IAP_BYPASS_VERIFY ("true" to skip verification for testing)

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.7";

function addDaysIso(days: number): string {
  const d = new Date();
  d.setDate(d.getDate() + days);
  return d.toISOString();
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { status: 200 });
  if (req.method !== "POST") return new Response("Method not allowed", { status: 405 });

  const serviceRoleKey = Deno.env.get("SERVICE_ROLE_KEY");
  if (!serviceRoleKey) return new Response("Missing SERVICE_ROLE_KEY", { status: 500 });

  const supabaseUrl =
    Deno.env.get("PROJECT_URL") ?? "https://uhquiaattcdarsyvogmj.supabase.co";

  const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  const authHeader = req.headers.get("authorization") ?? req.headers.get("Authorization");
  const token = authHeader?.startsWith("Bearer ") ? authHeader.slice("Bearer ".length) : undefined;
  if (!token) return new Response("Missing Authorization token", { status: 401 });

  const { data: userData, error: userErr } = await supabaseAdmin.auth.getUser(token);
  const user = userData?.user;
  if (userErr || !user) return new Response("Invalid token", { status: 401 });

  const body = await req.json().catch(() => null) as any;
  if (!body) return new Response("Invalid JSON body", { status: 400 });

  const platform = String(body.platform ?? "");
  const productId = String(body.product_id ?? "");
  const verificationData = body.verification_data ? String(body.verification_data) : undefined;

  if (!productId) return new Response("Missing product_id", { status: 400 });

  const bypass = (Deno.env.get("IAP_BYPASS_VERIFY") ?? "").toLowerCase() === "true";
  if (!bypass) {
    // We purposely fail closed until proper verification keys are configured.
    return new Response(
      "Verification not configured. Set IAP_BYPASS_VERIFY=true for testing, or implement store verification.",
      { status: 501 },
    );
  }

  // Best-effort period based on product id naming.
  const lower = productId.toLowerCase();
  const plan = lower.includes("year") ? "yearly" : "monthly";
  const paidUntilIso = plan == "yearly" ? addDaysIso(365) : addDaysIso(30);

  const { error: upErr } = await supabaseAdmin
    .from("user_profiles")
    .update({
      user_sub_plan: plan,
      user_sub_paid_until: paidUntilIso,
      updated_at: new Date().toISOString(),
    })
    .eq("user_id", user.id);

  if (upErr) return new Response(`Failed to update profile: ${upErr.message}`, { status: 500 });

  return new Response(
    JSON.stringify({ ok: true, platform, productId, plan, paid_until: paidUntilIso, bypass: true }),
    { status: 200, headers: { "content-type": "application/json" } },
  );
});

