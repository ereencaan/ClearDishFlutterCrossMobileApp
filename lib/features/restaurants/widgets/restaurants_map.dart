import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cleardish/data/models/restaurant.dart';

/// Simple OpenStreetMap map showing user's location and nearby restaurants.
class RestaurantsMap extends StatelessWidget {
  const RestaurantsMap({
    super.key,
    required this.userLat,
    required this.userLng,
    required this.restaurants,
    this.height = 240,
  });

  final double userLat;
  final double userLng;
  final List<Restaurant> restaurants;
  final double height;

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[
      // User location marker
      Marker(
        point: LatLng(userLat, userLng),
        width: 40,
        height: 40,
        child: const Icon(Icons.my_location, color: Colors.blue, size: 28),
      ),
      // Restaurant markers
      ...restaurants
          .where((r) => r.lat != null && r.lng != null)
          .map(
            (r) => Marker(
              point: LatLng(r.lat!, r.lng!),
              width: 40,
              height: 40,
              child:
                  const Icon(Icons.location_on, color: Colors.red, size: 32),
            ),
          ),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: height,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(userLat, userLng),
            initialZoom: 14,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'cleardish',
            ),
            MarkerLayer(markers: markers),
          ],
        ),
      ),
    );
  }
}


