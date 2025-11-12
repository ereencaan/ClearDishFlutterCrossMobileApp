import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cleardish/data/models/restaurant.dart';
import 'package:url_launcher/url_launcher.dart';

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
      ...restaurants.where((r) => r.lat != null && r.lng != null).map(
            (r) => Marker(
              point: LatLng(r.lat!, r.lng!),
              width: 44,
              height: 44,
              child: GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    builder: (context) => _RestaurantSheet(restaurant: r),
                  );
                },
                child:
                    const Icon(Icons.location_on, color: Colors.red, size: 34),
              ),
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

class _RestaurantSheet extends StatelessWidget {
  const _RestaurantSheet({required this.restaurant});
  final Restaurant restaurant;

  Future<void> _openDirections() async {
    if (restaurant.lat == null || restaurant.lng == null) return;
    final url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${restaurant.lat},${restaurant.lng}');
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            restaurant.name,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          if (restaurant.address != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16),
                const SizedBox(width: 6),
                Expanded(child: Text(restaurant.address!)),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              FilledButton.icon(
                onPressed: _openDirections,
                icon: const Icon(Icons.directions),
                label: const Text('Get directions'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Close'),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
