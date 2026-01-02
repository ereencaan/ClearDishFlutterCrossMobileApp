import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import 'package:cleardish/widgets/app_back_button.dart';
import 'package:cleardish/data/sources/restaurant_settings_api.dart';
import 'package:cleardish/data/sources/supabase_client.dart';
import 'package:cleardish/core/utils/result.dart';
import 'package:cleardish/data/sources/user_subscription_api.dart';
import 'package:cleardish/features/subscription/iap/iap_facade.dart';

final _ownerPaymentInfoProvider =
    FutureProvider.autoDispose((ref) async {
  final api = RestaurantSettingsApi(SupabaseClient.instance);
  return api.getOwnerPaymentInfo();
});

final _userSubscriptionProvider = FutureProvider.autoDispose((ref) async {
  final api = UserSubscriptionApi(SupabaseClient.instance);
  return api.getMySubscription();
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
    return const _UserIapPanel();
  }
}

class _UserIapPanel extends ConsumerStatefulWidget {
  const _UserIapPanel();

  @override
  ConsumerState<_UserIapPanel> createState() => _UserIapPanelState();
}

class _UserIapPanelState extends ConsumerState<_UserIapPanel> {
  static const _monthlyId = 'cleardish_user_monthly';
  static const _yearlyId = 'cleardish_user_yearly';

  late final IapFacade _iap;
  late final Set<String> _productIds;

  List<IapProduct> _products = const [];
  bool _loadingProducts = true;
  String? _storeError;

  @override
  void initState() {
    super.initState();
    _iap = createIapFacade();
    _productIds = const {_monthlyId, _yearlyId};

    _iap.purchaseStream.listen(_onPurchases, onError: (e) {
      if (!mounted) return;
      setState(() => _storeError = e.toString());
    });

    _loadProducts();
  }

  Future<void> _loadProducts() async {
    if (!_iap.isSupported || kIsWeb) {
      setState(() {
        _loadingProducts = false;
        _storeError = kIsWeb ? 'In-app purchases are not available on web.' : null;
      });
      return;
    }

    try {
      final products = await _iap.queryProducts(_productIds);
      if (!mounted) return;
      setState(() {
        _products = products;
        _loadingProducts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingProducts = false;
        _storeError = e.toString();
      });
    }
  }

  Future<void> _onPurchases(List<IapPurchase> purchases) async {
    for (final p in purchases) {
      if (p.status == IapPurchaseStatus.purchased ||
          p.status == IapPurchaseStatus.restored) {
        // Best-effort server confirmation: call Supabase Edge Function.
        await _verifyAndApply(p);
      } else if (p.status == IapPurchaseStatus.error && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(p.errorMessage ?? 'Purchase failed')),
        );
      }
    }
  }

  String _platformName() {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      _ => 'other',
    };
  }

  Future<void> _verifyAndApply(IapPurchase p) async {
    final user = supa.Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final resp = await SupabaseClient.instance.supabaseClient.client.functions
          .invoke('iap-verify', body: {
        'platform': _platformName(),
        'product_id': p.productId,
        'verification_data': p.verificationData,
      });

      if (resp.status != 200) {
        throw Exception(resp.data?.toString() ?? 'Verify failed');
      }

      ref.invalidate(_userSubscriptionProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subscription activated.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Purchase received. Waiting for activation… ($e)'),
        ),
      );
    }
  }

  IapProduct? _productById(String id) {
    for (final p in _products) {
      if (p.id == id) return p;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final subAsync = ref.watch(_userSubscriptionProvider);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.subscriptions,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            subAsync.when(
              loading: () => const Text('Loading your plan...'),
              error: (e, _) => Text('Failed to load: $e'),
              data: (res) {
                final info = res.dataOrNull;
                final active = info?.active == true;
                final plan = info?.plan ?? 'free';
                final until = info?.paidUntil;
                return Column(
                  children: [
                    Text(
                      active ? 'Current plan: $plan' : 'Current plan: Free',
                      style:
                          text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                      textAlign: TextAlign.center,
                    ),
                    if (active && until != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Renews after ${until.toIso8601String().split('T').first}',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            if (_loadingProducts) const CircularProgressIndicator(),
            if (_storeError != null) ...[
              Text(
                _storeError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.orange),
              ),
              const SizedBox(height: 8),
            ],
            if (!_loadingProducts && _iap.isSupported && !kIsWeb) ...[
              _PlanCard(
                title: 'Monthly',
                subtitle: '£4.99 / month',
                product: _productById(_monthlyId),
                onBuy: () => _iap.buyNonConsumable(_monthlyId),
              ),
              const SizedBox(height: 10),
              _PlanCard(
                title: 'Yearly',
                subtitle: '£49.99 / year',
                product: _productById(_yearlyId),
                onBuy: () => _iap.buyNonConsumable(_yearlyId),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _iap.restorePurchases(),
                icon: const Icon(Icons.restore),
                label: const Text('Restore purchases'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.subtitle,
    required this.product,
    required this.onBuy,
  });

  final String title;
  final String subtitle;
  final IapProduct? product;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final price = product?.price;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(price ?? subtitle),
                ],
              ),
            ),
            FilledButton(
              onPressed: product == null ? null : onBuy,
              child: const Text('Subscribe'),
            )
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
