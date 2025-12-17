import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cleardish/data/models/restaurant.dart';
import 'package:cleardish/data/models/user_profile.dart';
import 'package:cleardish/data/sources/supabase_client.dart';
import 'package:cleardish/core/utils/result.dart';
import 'package:cleardish/features/restaurants/controllers/restaurants_controller.dart';
import 'package:cleardish/features/restaurants/widgets/restaurants_map.dart';
import 'package:cleardish/widgets/app_back_button.dart';

final adminUsersProvider = FutureProvider.autoDispose<List<UserProfile>>((ref) async {
  final rows = await SupabaseClient.instance.supabaseClient.client
      .from('user_profiles')
      .select()
      .order('full_name', ascending: true);
  return (rows as List)
      .map((e) => UserProfile.fromMap(e as Map<String, dynamic>))
      .toList();
});

final _adminRestaurantsForMapProvider =
    FutureProvider.autoDispose<List<Restaurant>>((ref) async {
  final repo = ref.read(restaurantRepoProvider);
  final res = await repo.getRestaurants();
  if (res.isFailure) {
    throw Exception(res.errorOrNull ?? 'Failed to load restaurants');
  }
  return res.dataOrNull ?? const [];
});

class AdminUsersScreen extends ConsumerWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(adminUsersProvider);
    final mapAsync = ref.watch(_adminRestaurantsForMapProvider);
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallbackRoute: '/admin'),
        title: const Text('All Users'),
      ),
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load users: $e')),
        data: (users) {
          if (users.isEmpty) return const Center(child: Text('No users'));
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              mapAsync.when(
                loading: () => const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => const SizedBox.shrink(),
                data: (restaurants) {
                  final center = _firstPoint(restaurants) ?? (51.5074, -0.1278);
                  final hasCoords =
                      restaurants.any((r) => r.lat != null && r.lng != null);
                  if (!hasCoords) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: RestaurantsMap(
                      userLat: center.$1,
                      userLng: center.$2,
                      restaurants: restaurants,
                      height: 200,
                    ),
                  );
                },
              ),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: users.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final u = users[i];
                  return ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(u.fullName ?? u.userId),
                    subtitle: Text([
                      if ((u.allergens).isNotEmpty)
                        'Allergens: ${u.allergens.join(', ')}',
                      if ((u.diets).isNotEmpty)
                        'Diets: ${u.diets.join(', ')}',
                    ].join('  •  ')),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

(double, double)? _firstPoint(List<Restaurant> restaurants) {
  for (final r in restaurants) {
    if (r.lat != null && r.lng != null) return (r.lat!, r.lng!);
  }
  return null;
}
