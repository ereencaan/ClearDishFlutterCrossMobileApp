import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cleardish/data/models/restaurant.dart';
import 'package:cleardish/data/sources/restaurant_api.dart';
import 'package:cleardish/data/sources/supabase_client.dart';
import 'package:cleardish/features/restaurants/widgets/restaurants_map.dart';
import 'package:cleardish/widgets/app_back_button.dart';
import 'package:cleardish/core/utils/result.dart';

final _nearbyProvider =
    FutureProvider.autoDispose<_NearbyPayload>((ref) async {
  final permission = await Geolocator.checkPermission();
  LocationPermission granted = permission;
  if (permission == LocationPermission.denied) {
    granted = await Geolocator.requestPermission();
  }
  if (granted == LocationPermission.denied ||
      granted == LocationPermission.deniedForever) {
    throw Exception('Location permission denied');
  }
  final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high);
  final api = RestaurantApi(SupabaseClient.instance);
  final result = await api.getNearbyRestaurants(
      lat: pos.latitude, lng: pos.longitude, radiusKm: 5);
  if (result.isFailure) throw Exception(result.errorOrNull);
  return _NearbyPayload(position: pos, restaurants: result.dataOrNull!);
});

class NearbyRestaurantsScreen extends ConsumerWidget {
  const NearbyRestaurantsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncNearby = ref.watch(_nearbyProvider);
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallbackRoute: '/admin'),
        title: const Text('Nearby Restaurants'),
      ),
      body: asyncNearby.when(
        data: (payload) {
          final list = payload.restaurants;
          if (list.isEmpty) {
            return const Center(child: Text('No restaurants nearby'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              RestaurantsMap(
                userLat: payload.position.latitude,
                userLng: payload.position.longitude,
                restaurants: list,
                height: 220,
              ),
              const SizedBox(height: 12),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: list.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final r = list[index];
                  final distance = r.distanceMeters != null
                      ? (r.distanceMeters! / 1000).toStringAsFixed(2)
                      : null;
                  return ListTile(
                    title: Text(r.name),
                    subtitle: Text(r.address ?? 'No address'),
                    trailing: distance != null ? Text('$distance km') : null,
                  );
                },
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(e.toString()),
          ),
        ),
      ),
    );
  }
}

class _NearbyPayload {
  _NearbyPayload({required this.position, required this.restaurants});
  final Position position;
  final List<Restaurant> restaurants;
}
