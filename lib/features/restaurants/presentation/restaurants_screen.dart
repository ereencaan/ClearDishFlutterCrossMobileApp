import 'package:flutter/material.dart';
import 'dart:ui' show PointerDeviceKind;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cleardish/data/models/restaurant.dart';
import 'package:cleardish/data/sources/restaurant_api.dart';
import 'package:cleardish/data/sources/restaurant_settings_api.dart';
import 'package:cleardish/data/sources/supabase_client.dart';
import 'package:cleardish/features/restaurants/widgets/restaurants_map.dart';
import 'package:cleardish/core/utils/result.dart';
import 'package:cleardish/features/restaurants/controllers/restaurants_controller.dart';
import 'package:cleardish/features/restaurants/widgets/restaurant_card.dart';

final _ownerRestaurantProvider =
    FutureProvider.autoDispose<Result<Restaurant>>((ref) async {
  final api = RestaurantSettingsApi(SupabaseClient.instance);
  return api.getMyRestaurant();
});

/// Restaurants list screen
///
/// Displays a list of available restaurants with search functionality.
class RestaurantsScreen extends ConsumerStatefulWidget {
  const RestaurantsScreen({super.key});

  @override
  ConsumerState<RestaurantsScreen> createState() => _RestaurantsScreenState();
}

class _RestaurantsScreenState extends ConsumerState<RestaurantsScreen> {
  final _searchController = TextEditingController();
  late Future<_NearbyPayload> _nearbyFuture;

  @override
  void initState() {
    super.initState();
    _nearbyFuture = _loadNearby();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<_NearbyPayload> _loadNearby() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        throw Exception('Location permission denied');
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final api = RestaurantApi(SupabaseClient.instance);
      final result = await api.getNearbyRestaurants(
        lat: pos.latitude,
        lng: pos.longitude,
        radiusKm: 5,
      );
      if (result.isFailure) {
        throw Exception(result.errorOrNull);
      }
      return _NearbyPayload(position: pos, restaurants: result.dataOrNull!);
    } catch (e) {
      return _NearbyPayload(error: e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(restaurantsControllerProvider);
    final user = SupabaseClient.instance.auth.currentUser;
    final role = user?.userMetadata?['role'] as String?;
    final isOwner = role == 'restaurant';

    // Update search query when text changes
    _searchController.addListener(() {
      ref.read(restaurantsControllerProvider.notifier).updateSearchQuery(
            _searchController.text,
          );
    });

    if (isOwner) {
      return const _OwnerRestaurantOverview();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurants'),
      ),
      body: Column(
        children: [
          // Map + nearby section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: FutureBuilder<_NearbyPayload>(
              future: _nearbyFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 240,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final data = snapshot.data;
                if (data == null || data.error != null) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.location_off, color: Colors.orange),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Enable location to see nearby restaurants on the map.',
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    RestaurantsMap(
                      userLat: data.position!.latitude,
                      userLng: data.position!.longitude,
                      restaurants: data.restaurants,
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Nearby restaurants',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Horizontal scroll with drag-friendly SingleChildScrollView
                    SizedBox(
                      height: 130,
                      child: ScrollConfiguration(
                        behavior: const _DragScrollBehavior(),
                        child: ListView.separated(
                          primary: false,
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.zero,
                          itemCount: data.restaurants.length.clamp(0, 10),
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final r = data.restaurants[index];
                            return _NearbyCard(
                              restaurant: r,
                              onTap: () =>
                                  context.go('/home/restaurants/${r.id}'),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search restaurants...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
              ),
            ),
          ),
          Expanded(
            child: _buildBody(state),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(RestaurantsState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error: ${state.error}',
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref
                    .read(restaurantsControllerProvider.notifier)
                    .loadRestaurants();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.filteredRestaurants.isEmpty) {
      return const Center(
        child: Text('No restaurants found'),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(restaurantsControllerProvider.notifier)
            .loadRestaurants();
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: state.filteredRestaurants.length,
        itemBuilder: (context, index) {
          final restaurant = state.filteredRestaurants[index];
          return RestaurantCard(
            restaurant: restaurant,
            onTap: () {
              context.go('/home/restaurants/${restaurant.id}');
            },
          );
        },
      ),
    );
  }
}

class _NearbyPayload {
  _NearbyPayload({
    this.position,
    this.restaurants = const [],
    this.error,
  });
  final Position? position;
  final List<Restaurant> restaurants;
  final String? error;
}

class _NearbyCard extends StatelessWidget {
  const _NearbyCard({required this.restaurant, required this.onTap});
  final Restaurant restaurant;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final distanceKm = restaurant.distanceMeters != null
        ? (restaurant.distanceMeters! / 1000).toStringAsFixed(2)
        : null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(.4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              restaurant.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              restaurant.address ?? 'No address',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Spacer(),
            if (distanceKm != null)
              Text(
                '$distanceKm km',
                style: Theme.of(context).textTheme.labelLarge,
              ),
          ],
        ),
      ),
    );
  }
}

class _OwnerRestaurantOverview extends ConsumerWidget {
  const _OwnerRestaurantOverview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultAsync = ref.watch(_ownerRestaurantProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Restaurant'),
      ),
      body: resultAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed: $e')),
        data: (result) {
          if (result.isFailure) {
            return Center(child: Text(result.errorOrNull ?? 'Failed'));
          }
          final restaurant = result.dataOrNull!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          restaurant.name,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        if (restaurant.address != null)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.location_on, size: 18),
                              const SizedBox(width: 8),
                              Expanded(child: Text(restaurant.address!)),
                            ],
                          ),
                        if (restaurant.phone != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.phone, size: 18),
                              const SizedBox(width: 8),
                              Text(restaurant.phone!),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () =>
                              context.go('/home/restaurant/settings'),
                          icon: const Icon(Icons.edit_location),
                          label: const Text('Edit contact / address'),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () => context.go('/home/restaurant/setup'),
                          icon: const Icon(Icons.menu_book),
                          label: const Text('Manage Menu'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (restaurant.lat != null && restaurant.lng != null)
                  RestaurantsMap(
                    userLat: restaurant.lat!,
                    userLng: restaurant.lng!,
                    restaurants: [restaurant],
                    height: 240,
                  )
                else
                  Container(
                    height: 160,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text('Add coordinates to preview map'),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Ensures horizontal lists can be dragged with touch, mouse and trackpad
class _DragScrollBehavior extends ScrollBehavior {
  const _DragScrollBehavior();
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}
