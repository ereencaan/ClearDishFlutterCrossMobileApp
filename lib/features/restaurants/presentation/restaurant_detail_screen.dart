import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cleardish/data/repositories/restaurant_repo.dart';
import 'package:cleardish/data/models/restaurant.dart';
import 'package:cleardish/core/utils/result.dart';
import 'package:cleardish/features/restaurants/widgets/restaurants_map.dart';
import 'package:cleardish/widgets/app_back_button.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cleardish/data/sources/postcode_api.dart';

/// Restaurant detail screen
///
/// Shows restaurant details and navigation to menu.
class RestaurantDetailScreen extends ConsumerStatefulWidget {
  const RestaurantDetailScreen({
    required this.restaurantId,
    super.key,
  });

  final String restaurantId;

  @override
  ConsumerState<RestaurantDetailScreen> createState() =>
      _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState
    extends ConsumerState<RestaurantDetailScreen> {
  Restaurant? _restaurant;
  bool _isLoading = true;
  String? _error;
  double? _latOverride;
  double? _lngOverride;
  String? _addressOverride;

  @override
  void initState() {
    super.initState();
    _loadRestaurant();
  }

  Future<void> _loadRestaurant() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final repo = RestaurantRepo();
    final result = await repo.getRestaurant(widget.restaurantId);

    if (result.isSuccess) {
      final r = result.dataOrNull!;
      // If coordinates are missing or outside UK bounds, try postcode lookup.
      final invalidCoords = (r.lat == null ||
          r.lng == null ||
          r.lat! < 49.0 ||
          r.lat! > 61.0 ||
          r.lng! < -9.0 ||
          r.lng! > 3.0);
      if (invalidCoords && (r.address != null && r.address!.isNotEmpty)) {
        final pc = _extractUkPostcode(r.address!);
        if (pc != null) {
          try {
            final detail = await PostcodeApi().lookup(pc);
            _latOverride = detail.latitude;
            _lngOverride = detail.longitude;
            _addressOverride = detail.formattedAddress();
          } catch (_) {
            // ignore lookup errors; fall back to original data
          }
        }
      }
    }

    setState(() {
      _isLoading = false;
      if (result.isFailure) {
        _error = result.errorOrNull;
      } else {
        _restaurant = result.dataOrNull;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant Details'),
        leading: const AppBackButton(
          fallbackRoute: '/home/restaurants',
        ),
      ),
      body: _buildBody(),
      floatingActionButton: _restaurant != null
          ? FloatingActionButton.extended(
              onPressed: () {
                context.go('/home/menu/${widget.restaurantId}');
              },
              label: const Text('View Menu'),
              icon: const Icon(Icons.restaurant_menu),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error: $_error',
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadRestaurant,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_restaurant == null) {
      return const Center(child: Text('Restaurant not found'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _restaurant!.name,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          if ((_latOverride ?? _restaurant!.lat) != null &&
              (_lngOverride ?? _restaurant!.lng) != null)
            RestaurantsMap(
              userLat: (_latOverride ?? _restaurant!.lat!),
              userLng: (_lngOverride ?? _restaurant!.lng!),
              restaurants: [
                Restaurant(
                  id: _restaurant!.id,
                  name: _restaurant!.name,
                  address: _addressOverride ?? _restaurant!.address,
                  phone: _restaurant!.phone,
                  lat: _latOverride ?? _restaurant!.lat,
                  lng: _lngOverride ?? _restaurant!.lng,
                  visible: _restaurant!.visible,
                  createdAt: _restaurant!.createdAt,
                  distanceMeters: _restaurant!.distanceMeters,
                )
              ],
              height: 220,
            ),
          if ((_addressOverride ?? _restaurant!.address) != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.location_on),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    (_addressOverride ?? _restaurant!.address!),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () async {
                final lat = _latOverride ?? _restaurant!.lat;
                final lng = _lngOverride ?? _restaurant!.lng;
                if (lat != null && lng != null) {
                  final url = Uri.parse(
                    'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
                  );
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(Icons.directions),
              label: const Text('Get directions'),
            ),
          ],
        ],
      ),
    );
  }

  String? _extractUkPostcode(String text) {
    final re = RegExp(
      r'([A-Z]{1,2}\d{1,2}[A-Z]?)\s?(\d[A-Z]{2})',
      caseSensitive: false,
    );
    final m = re.firstMatch(text.toUpperCase());
    if (m != null) {
      return '${m.group(1)} ${m.group(2)}';
    }
    return null;
  }
}
