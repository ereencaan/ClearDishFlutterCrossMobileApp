import 'package:cleardish/data/sources/restaurant_diet_tags_api.dart';
import 'package:cleardish/data/sources/restaurant_settings_api.dart';
import 'package:cleardish/data/sources/supabase_client.dart';
import 'package:cleardish/widgets/app_back_button.dart';
import 'package:cleardish/core/utils/result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _myRestaurantProvider = FutureProvider.autoDispose((ref) async {
  final api = RestaurantSettingsApi(SupabaseClient.instance);
  return api.getMyRestaurant();
});

final _ownerPaymentProvider = FutureProvider.autoDispose((ref) async {
  final api = RestaurantSettingsApi(SupabaseClient.instance);
  return api.getOwnerPaymentInfo();
});

final _dietTagsProvider =
    FutureProvider.autoDispose.family((ref, String restaurantId) async {
  final api = RestaurantDietTagsApi(SupabaseClient.instance);
  return api.listTags(restaurantId: restaurantId);
});

class RestaurantDietTagsScreen extends ConsumerWidget {
  const RestaurantDietTagsScreen({super.key});

  bool _isProOrPlus(String? plan) {
    final p = (plan ?? '').toLowerCase();
    return p == 'pro' || p == 'plus';
  }

  static const List<String> _defaultTags = [
    'vegan',
    'vegetarian',
    'halal',
    'gluten-free',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payAsync = ref.watch(_ownerPaymentProvider);
    final myRAsync = ref.watch(_myRestaurantProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallbackRoute: '/home/restaurants'),
        title: const Text('Diet tags'),
      ),
      body: payAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load plan: $e')),
        data: (payRes) {
          final plan = payRes.dataOrNull?.plan;
          final allowed = _isProOrPlus(plan);

          return myRAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Failed to load restaurant: $e')),
            data: (rRes) {
              if (rRes.isFailure) {
                return Center(child: Text(rRes.errorOrNull ?? 'No restaurant'));
              }
              final restaurant = rRes.dataOrNull!;
              final tagsAsync = ref.watch(_dietTagsProvider(restaurant.id));

              return tagsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Failed to load tags: $e')),
                data: (tagRes) {
                  final tags = tagRes.dataOrNull ?? const <String>[];
                  final all = <String>{..._defaultTags, ...tags}.toList()..sort();

                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                const Icon(Icons.lock_outline),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    allowed
                                        ? 'Pro/Plus: diet tags enabled'
                                        : 'Upgrade to Pro to enable diet tags',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: all.map((t) {
                            final selected = tags.contains(t);
                            return FilterChip(
                              selected: selected,
                              label: Text(t),
                              onSelected: !allowed
                                  ? null
                                  : (v) async {
                                      final next = <String>{...tags};
                                      if (v) {
                                        next.add(t);
                                      } else {
                                        next.remove(t);
                                      }
                                      final api = RestaurantDietTagsApi(
                                        SupabaseClient.instance,
                                      );
                                      final res = await api.replaceTags(
                                        restaurantId: restaurant.id,
                                        tags: next.toList(),
                                      );
                                      if (!context.mounted) return;
                                      if (res.isFailure) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(res.errorOrNull ?? 'Failed'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      } else {
                                        ref.invalidate(_dietTagsProvider(restaurant.id));
                                      }
                                    },
                            );
                          }).toList(),
                        ),
                        const Spacer(),
                        FilledButton.icon(
                          onPressed: !allowed
                              ? null
                              : () async {
                                  final tag = await _promptAddCustomTag(context);
                                  if (tag == null) return;
                                  final api = RestaurantDietTagsApi(
                                    SupabaseClient.instance,
                                  );
                                  final res = await api.replaceTags(
                                    restaurantId: restaurant.id,
                                    tags: [...tags, tag],
                                  );
                                  if (!context.mounted) return;
                                  if (res.isFailure) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(res.errorOrNull ?? 'Failed'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  } else {
                                    ref.invalidate(_dietTagsProvider(restaurant.id));
                                  }
                                },
                          icon: const Icon(Icons.add),
                          label: const Text('Add custom tag'),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<String?> _promptAddCustomTag(BuildContext context) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Custom tag'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Tag (e.g. kosher, dairy-free)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final t = ctrl.text.trim().toLowerCase();
              Navigator.of(context).pop(t.isEmpty ? null : t);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

