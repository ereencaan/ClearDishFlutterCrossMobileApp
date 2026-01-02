import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import 'package:cleardish/widgets/app_back_button.dart';
import 'package:cleardish/data/sources/restaurant_settings_api.dart';
import 'package:cleardish/data/sources/supabase_client.dart';
import 'package:cleardish/core/utils/result.dart';

final _ownerPaymentInfoProvider =
    FutureProvider.autoDispose((ref) async {
  final api = RestaurantSettingsApi(SupabaseClient.instance);
  return api.getOwnerPaymentInfo();
});

/// Subscription screen
///
/// - Users: (future) in-app subscription.
/// - Restaurant owners: managed externally (website), but status is shown here.
class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = supa.Supabase.instance.client.auth.currentUser;
    final role = user?.userMetadata?['role'] as String?;
    final isOwner = role == 'restaurant';

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallbackRoute: '/home'),
        title: const Text('Subscription'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: isOwner
              ? _OwnerSubscriptionPanel(ref: ref)
              : const _UserSubscriptionPanel(),
        ),
      ),
    );
  }
}

class _UserSubscriptionPanel extends StatelessWidget {
  const _UserSubscriptionPanel();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.subscriptions,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Current plan: Free',
              style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'User subscriptions (in-app) will appear here.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: null,
              child: const Text('Upgrade (coming soon)'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OwnerSubscriptionPanel extends StatelessWidget {
  const _OwnerSubscriptionPanel({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final asyncRes = ref.watch(_ownerPaymentInfoProvider);

    return asyncRes.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _OwnerPanelFrame(
        title: 'Business subscription',
        child: Text('Failed to load subscription status: $e'),
        onRefresh: () async {
          await SupabaseClient.instance.supabaseClient.client.auth.getUser();
          ref.invalidate(_ownerPaymentInfoProvider);
        },
      ),
      data: (res) {
        final info = res.dataOrNull;
        final active = info?.active == true;
        final plan = (info?.plan?.trim().isNotEmpty == true)
            ? info!.plan!.trim()
            : 'Active';
        final until = info?.paidUntil;

        return _OwnerPanelFrame(
          title: 'Business subscription',
          onRefresh: () async {
            await SupabaseClient.instance.supabaseClient.client.auth.getUser();
            ref.invalidate(_ownerPaymentInfoProvider);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            active ? Icons.verified : Icons.lock,
                            color: active ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              active ? 'Active' : 'Payment required',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('Plan: $plan'),
                      if (until != null)
                        Text(
                          'Renews after ${until.toIso8601String().split('T').first}',
                        ),
                      const SizedBox(height: 12),
                      const Text(
                        'Plans: Starter £19/mo • Pro £39/mo • Plus £79/mo',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => _openOwnerPayment(context),
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Upgrade / downgrade plan'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  final uri = Uri.https('cleardish.co.uk', '/restaurant-payment/');
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open billing website'),
              ),
              const SizedBox(height: 8),
              Text(
                'Note: Billing is handled on our website due to store policy requirements.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OwnerPanelFrame extends StatelessWidget {
  const _OwnerPanelFrame({
    required this.title,
    required this.child,
    required this.onRefresh,
  });

  final String title;
  final Widget child;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            IconButton(
              tooltip: 'Refresh',
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(child: SingleChildScrollView(child: child)),
      ],
    );
  }
}

Future<void> _openOwnerPayment(BuildContext context) async {
  final user = SupabaseClient.instance.auth.currentUser;
  final uid = user?.id ?? '';
  final email = user?.email ?? '';
  final returnUrl = 'cleardish://payment-complete';
  const plans = [
    {'id': 'starter', 'label': 'Starter - £19/mo'},
    {'id': 'pro', 'label': 'Pro - £39/mo'},
    {'id': 'plus', 'label': 'Plus - £79/mo'},
  ];

  String current = plans.first['id']!;

  final selectedPlan = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setSt) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose a plan',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                ...plans.map(
                  (p) => RadioListTile<String>(
                    value: p['id']!,
                    groupValue: current,
                    title: Text(p['label']!),
                    onChanged: (val) {
                      if (val != null) setSt(() => current = val);
                    },
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(current),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open payment page'),
                ),
              ],
            ),
          );
        },
      );
    },
  );

  if (selectedPlan == null) return;

  final normalizedPlan = selectedPlan.trim().toLowerCase();
  final slug = switch (normalizedPlan) {
    'starter' => 'restaurant-payment-starter',
    'pro' => 'restaurant-payment-pro',
    'plus' => 'restaurant-payment-plus',
    _ => 'restaurant-payment',
  };

  final url = Uri.https('cleardish.co.uk', '/$slug/', {
    'uid': uid,
    'email': email,
    'plan': normalizedPlan,
    'return_url': returnUrl,
  }).toString();

  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}
