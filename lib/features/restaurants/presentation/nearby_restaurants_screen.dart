import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cleardish/data/sources/restaurant_api.dart';
import 'package:cleardish/data/sources/supabase_client.dart';
import 'package:cleardish/data/models/restaurant.dart';
import 'package:cleardish/core/utils/result.dart';

final _nearbyProvider = FutureProvider.autoDispose<List<Restaurant>>((ref) async {
  final permission = await Geolocator.checkPermission();
  LocationPermission granted = permission;
  if (permission == LocationPermission.denied) {
    granted = await Geolocator.requestPermission();
  }
  if (granted == LocationPermission.denied || granted == LocationPermission.deniedForever) {
    throw Exception('Location permission denied');
  }
  final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  final api = RestaurantApi(SupabaseClient.instance);
  final result = await api.getNearbyRestaurants(lat: pos.latitude, lng: pos.longitude, radiusKm: 5);
  if (result.isFailure) throw Exception(result.errorOrNull);
  return result.dataOrNull!;
});

class NearbyRestaurantsScreen extends ConsumerWidget {
  const NearbyRestaurantsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncNearby = ref.watch(_nearbyProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Nearby Restaurants')),
      body: asyncNearby.when(
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('No restaurants nearby'));
          }
          return ListView.separated(
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
