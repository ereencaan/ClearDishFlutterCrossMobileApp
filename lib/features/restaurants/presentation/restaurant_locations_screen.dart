import 'package:cleardish/core/utils/result.dart';
import 'package:cleardish/data/models/restaurant_location.dart';
import 'package:cleardish/data/sources/restaurant_locations_api.dart';
import 'package:cleardish/data/sources/restaurant_settings_api.dart';
import 'package:cleardish/data/sources/supabase_client.dart';
import 'package:cleardish/widgets/app_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final _myRestaurantProvider = FutureProvider.autoDispose((ref) async {
  final api = RestaurantSettingsApi(SupabaseClient.instance);
  return api.getMyRestaurant();
});

final _ownerPaymentProvider = FutureProvider.autoDispose((ref) async {
  final api = RestaurantSettingsApi(SupabaseClient.instance);
  return api.getOwnerPaymentInfo();
});

final _locationsProvider =
    FutureProvider.autoDispose.family<Result<List<RestaurantLocation>>, String>(
        (ref, restaurantId) async {
  final api = RestaurantLocationsApi(SupabaseClient.instance);
  return api.listLocations(restaurantId: restaurantId);
});

class RestaurantLocationsScreen extends ConsumerWidget {
  const RestaurantLocationsScreen({super.key});

  bool _isPlus(String? plan) => (plan ?? '').toLowerCase() == 'plus';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payAsync = ref.watch(_ownerPaymentProvider);
    final myRAsync = ref.watch(_myRestaurantProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallbackRoute: '/home/restaurants'),
        title: const Text('Locations'),
      ),
      body: payAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load plan: $e')),
        data: (payRes) {
          final info = payRes.dataOrNull;
          final plan = info?.plan;
          final isPlus = _isPlus(plan);

          return myRAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Failed to load restaurant: $e')),
            data: (rRes) {
              if (rRes.isFailure) {
                return Center(child: Text(rRes.errorOrNull ?? 'No restaurant'));
              }
              final restaurant = rRes.dataOrNull!;
              final locAsync = ref.watch(_locationsProvider(restaurant.id));
              return locAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Failed to load: $e')),
                data: (locRes) {
                  final locations = locRes.dataOrNull ?? const <RestaurantLocation>[];
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
                                const Icon(Icons.info_outline),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    isPlus
                                        ? 'Plus: unlimited locations'
                                        : 'Starter/Pro: 1 location (upgrade to Plus for multi-location)',
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => context.go('/home/subscription'),
                                  child: const Text('Upgrade'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: locations.isEmpty
                              ? const Center(child: Text('No locations yet'))
                              : ListView.separated(
                                  itemCount: locations.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                                  itemBuilder: (context, i) {
                                    final l = locations[i];
                                    return Card(
                                      child: ListTile(
                                        leading: Icon(
                                          l.isPrimary ? Icons.star : Icons.place,
                                        ),
                                        title: Text(l.label?.trim().isNotEmpty == true
                                            ? l.label!
                                            : (l.isPrimary ? 'Primary location' : 'Location')),
                                        subtitle: Text(l.address),
                                        trailing: PopupMenuButton<String>(
                                          onSelected: (v) async {
                                            if (v == 'edit') {
                                              await _showEditDialog(
                                                context,
                                                ref,
                                                restaurantId: restaurant.id,
                                                existing: l,
                                              );
                                            } else if (v == 'delete') {
                                              final api = RestaurantLocationsApi(
                                                SupabaseClient.instance,
                                              );
                                              final res = await api.deleteLocation(l.id);
                                              if (!context.mounted) return;
                                              if (res.isFailure) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text(res.errorOrNull ?? 'Failed'),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              } else {
                                                ref.invalidate(_locationsProvider(restaurant.id));
                                              }
                                            }
                                          },
                                          itemBuilder: (context) => const [
                                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                                            PopupMenuItem(value: 'delete', child: Text('Delete')),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () async {
                            if (!isPlus && locations.length >= 1) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Upgrade to Plus to add more locations'),
                                ),
                              );
                              return;
                            }
                            await _showEditDialog(
                              context,
                              ref,
                              restaurantId: restaurant.id,
                              existing: null,
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add location'),
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

  Future<void> _showEditDialog(
    BuildContext context,
    WidgetRef ref, {
    required String restaurantId,
    required RestaurantLocation? existing,
  }) async {
    final labelCtrl = TextEditingController(text: existing?.label ?? '');
    final addrCtrl = TextEditingController(text: existing?.address ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    bool primary = existing?.isPrimary ?? (existing == null);
    bool saving = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setSt) => AlertDialog(
          title: Text(existing == null ? 'Add location' : 'Edit location'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelCtrl,
                decoration: const InputDecoration(
                  labelText: 'Label (optional)',
                ),
              ),
              TextField(
                controller: addrCtrl,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Phone (optional)'),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: primary,
                onChanged: (v) => setSt(() => primary = v ?? false),
                title: const Text('Primary location'),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      final addr = addrCtrl.text.trim();
                      if (addr.isEmpty) return;
                      setSt(() => saving = true);
                      final api = RestaurantLocationsApi(SupabaseClient.instance);
                      final loc = existing == null
                          ? RestaurantLocation(
                              id: 'new',
                              restaurantId: restaurantId,
                              address: addr,
                              label: labelCtrl.text.trim().isEmpty
                                  ? null
                                  : labelCtrl.text.trim(),
                              phone: phoneCtrl.text.trim().isEmpty
                                  ? null
                                  : phoneCtrl.text.trim(),
                              isPrimary: primary,
                            )
                          : RestaurantLocation(
                              id: existing.id,
                              restaurantId: restaurantId,
                              address: addr,
                              label: labelCtrl.text.trim().isEmpty
                                  ? null
                                  : labelCtrl.text.trim(),
                              phone: phoneCtrl.text.trim().isEmpty
                                  ? null
                                  : phoneCtrl.text.trim(),
                              isPrimary: primary,
                              createdAt: existing.createdAt,
                              lat: existing.lat,
                              lng: existing.lng,
                            );

                      final res = existing == null
                          ? await api.createLocation(loc)
                          : await api.updateLocation(loc);
                      if (!context.mounted) return;
                      setSt(() => saving = false);
                      if (res.isFailure) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(res.errorOrNull ?? 'Failed'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      Navigator.of(context).pop();
                      ref.invalidate(_locationsProvider(restaurantId));
                    },
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

