import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cleardish/data/models/restaurant.dart';
import 'package:cleardish/features/restaurants/controllers/restaurants_controller.dart';
import 'package:cleardish/features/restaurants/widgets/restaurants_map.dart';
import 'package:cleardish/widgets/app_back_button.dart';
import 'package:cleardish/core/utils/result.dart';

final _adminRestaurantsProvider =
    FutureProvider.autoDispose<List<Restaurant>>((ref) async {
  final repo = ref.read(restaurantRepoProvider);
  final res = await repo.getRestaurants();
  if (res.isFailure) {
    throw Exception(res.errorOrNull);
  }
  return res.dataOrNull!;
});

class AdminRestaurantsScreen extends ConsumerWidget {
  const AdminRestaurantsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(_adminRestaurantsProvider);
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallbackRoute: '/admin'),
        title: const Text('Restaurants'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.go('/admin/restaurants/new'),
            tooltip: 'Add restaurant',
          ),
        ],
      ),
      body: asyncList.when(
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('No restaurants'));
          }
          final center = _centerPoint(list);
          final hasCoords =
              list.any((r) => r.lat != null && r.lng != null);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (hasCoords && center != null) ...[
                RestaurantsMap(
                  userLat: center.$1,
                  userLng: center.$2,
                  restaurants: list,
                  height: 220,
                ),
                const SizedBox(height: 16),
              ],
              ...list.map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        color: Theme.of(context)
                            .dividerColor
                            .withOpacity(.4),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Text(r.name),
                      subtitle: Text(r.address ?? 'No address'),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) async {
                          final repo = ref.read(restaurantRepoProvider);
                          if (v == 'edit') {
                            context.go('/admin/restaurants/${r.id}/edit');
                          } else if (v == 'terminate') {
                            final res = await repo.terminateRestaurant(r.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    res.isFailure
                                        ? (res.errorOrNull ?? 'Failed')
                                        : 'Partnership terminated',
                                  ),
                                ),
                              );
                            }
                            ref.invalidate(_adminRestaurantsProvider);
                          } else if (v == 'delete') {
                            final res = await repo.deleteRestaurant(r.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    res.isFailure
                                        ? (res.errorOrNull ?? 'Failed')
                                        : 'Deleted',
                                  ),
                                ),
                              );
                            }
                            ref.invalidate(_adminRestaurantsProvider);
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(
                            value: 'terminate',
                            child: Text('Terminate'),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(e.toString()),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

/// Returns the first available (lat, lng) pair from the list, or null.
(double, double)? _centerPoint(List<Restaurant> list) {
  for (final r in list) {
    if (r.lat != null && r.lng != null) {
      return (r.lat!, r.lng!);
    }
  }
  return null;
}
