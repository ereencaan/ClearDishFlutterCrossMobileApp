import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cleardish/data/models/restaurant.dart';
import 'package:cleardish/data/sources/restaurant_api.dart';
import 'package:cleardish/data/sources/restaurant_settings_api.dart';
import 'package:cleardish/data/sources/supabase_client.dart';
import 'package:cleardish/data/sources/postcode_api.dart';
import 'package:cleardish/features/restaurants/widgets/restaurants_map.dart';
import 'package:cleardish/core/utils/result.dart';
import 'package:cleardish/features/restaurants/controllers/restaurants_controller.dart';
import 'package:cleardish/features/restaurants/widgets/restaurant_card.dart';
import 'package:cleardish/features/auth/controllers/auth_controller.dart';
import 'package:cleardish/widgets/app_back_button.dart';

final _ownerRestaurantProvider =
    FutureProvider.autoDispose<Result<Restaurant>>((ref) async {
  final api = RestaurantSettingsApi(SupabaseClient.instance);
  return api.getMyRestaurant();
});

final _ownerPaymentStatusProvider =
    FutureProvider.autoDispose<Result<bool>>((ref) async {
  final api = RestaurantSettingsApi(SupabaseClient.instance);
  return api.getOwnerPaymentStatus();
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

  Future<void> _enableLocation() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm != LocationPermission.denied &&
          perm != LocationPermission.deniedForever) {
        // Proactively read position to trigger browser prompt if needed
        await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      }
    } catch (_) {
      // ignore
    } finally {
      if (mounted) {
        setState(() {
          _nearbyFuture = _loadNearby();
        });
      }
    }
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
        leading: const AppBackButton(fallbackRoute: '/home'),
        title: const Text('Restaurants'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context, ref),
          ),
        ],
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
                  final fallback = state.filteredRestaurants.isNotEmpty
                      ? state.filteredRestaurants
                      : state.restaurants;
                  final firstPoint = _firstPoint(fallback);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (firstPoint != null)
                        RestaurantsMap(
                          userLat: firstPoint.$1,
                          userLng: firstPoint.$2,
                          restaurants: fallback,
                        )
                      else
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.location_off,
                                        color: Colors.orange),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Enable location to see nearby restaurants on the map.',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: FilledButton.icon(
                                    onPressed: _enableLocation,
                                    icon: const Icon(Icons.my_location),
                                    label: const Text('Enable location'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                    ],
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
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
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

(double, double)? _firstPoint(List<Restaurant> restaurants) {
  for (final r in restaurants) {
    if (r.lat != null && r.lng != null) return (r.lat!, r.lng!);
  }
  return null;
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
    final paymentAsync = ref.watch(_ownerPaymentStatusProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Restaurant'),
        leading: const AppBackButton(fallbackRoute: '/home'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context, ref),
          ),
        ],
      ),
      body: paymentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _OwnerPaymentRequired(
          message: 'Payment check failed: $e',
          onPay: () => _openOwnerPayment(context),
          onRefresh: () {
            ref.invalidate(_ownerPaymentStatusProvider);
            ref.invalidate(_ownerRestaurantProvider);
          },
        ),
        data: (payResult) {
          if (payResult.isFailure || payResult.dataOrNull != true) {
            final msg = payResult.errorOrNull ??
                'Complete the business payment to continue';
            return _OwnerPaymentRequired(
              message: msg,
              onPay: () => _openOwnerPayment(context),
              onRefresh: () {
                ref.invalidate(_ownerPaymentStatusProvider);
                ref.invalidate(_ownerRestaurantProvider);
              },
            );
          }

          final resultAsync = ref.watch(_ownerRestaurantProvider);
          return resultAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _OwnerEmptyState(
                onCreate: () {
                  _showCreateDialog(context, ref);
                },
                message: 'Failed: $e'),
            data: (result) {
              if (result.isFailure) {
                final msg = result.errorOrNull ?? 'No restaurant assigned';
                return _OwnerEmptyState(
                  message: msg,
                  onCreate: () {
                    _showCreateDialog(context, ref);
                  },
                );
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
                              onPressed: () =>
                                  context.go('/home/restaurant/setup'),
                              icon: const Icon(Icons.menu_book),
                              label: const Text('Manage Menu'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _OwnerMapAutoLocate(restaurant: restaurant),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final addrCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        bool saving = false;
        return StatefulBuilder(builder: (context, setSt) {
          Future<void> _save() async {
            if (saving) return;
            setSt(() => saving = true);
            final api = RestaurantSettingsApi(SupabaseClient.instance);
            final res = await api.createRestaurantWithOwner(
              name: nameCtrl.text.trim().isEmpty
                  ? 'My Restaurant'
                  : nameCtrl.text.trim(),
              address: addrCtrl.text.trim().isEmpty
                  ? 'Address not set'
                  : addrCtrl.text.trim(),
              phone:
                  phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
            );
            setSt(() => saving = false);
            if (!context.mounted) return;
            if (res.isFailure) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(res.errorOrNull ?? 'Failed to create'),
                  backgroundColor: Colors.red));
              return;
            }
            Navigator.of(context).pop();
            ref.invalidate(_ownerRestaurantProvider);
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Restaurant created')));
          }

          return AlertDialog(
            title: const Text('Create your restaurant'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: addrCtrl,
                  decoration: const InputDecoration(labelText: 'Address'),
                ),
                TextField(
                  controller: phoneCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Phone (optional)'),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
            actions: [
              Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed:
                          saving ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: saving ? null : _save,
                      child: saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Create'),
                    ),
                  ),
                ],
              ),
            ],
          );
        });
      },
    );
  }
}

class _OwnerMapAutoLocate extends StatefulWidget {
  const _OwnerMapAutoLocate({required this.restaurant});
  final Restaurant restaurant;
  @override
  State<_OwnerMapAutoLocate> createState() => _OwnerMapAutoLocateState();
}

class _OwnerMapAutoLocateState extends State<_OwnerMapAutoLocate> {
  double? _lat;
  double? _lng;
  bool _loading = false;
  bool _attempted = false;

  @override
  void initState() {
    super.initState();
    _maybeResolveFromPostcode();
  }

  bool _invalidCoords(Restaurant r) {
    if (r.lat == null || r.lng == null) return true;
    final lat = r.lat!;
    final lng = r.lng!;
    return lat < 49.0 || lat > 61.0 || lng < -9.0 || lng > 3.0;
  }

  String? _extractUkPostcode(String text) {
    final re = RegExp(r'([A-Z]{1,2}\d{1,2}[A-Z]?)\s?(\d[A-Z]{2})',
        caseSensitive: false);
    final m = re.firstMatch(text.toUpperCase());
    if (m != null) {
      return '${m.group(1)} ${m.group(2)}';
    }
    return null;
  }

  Future<void> _maybeResolveFromPostcode() async {
    final r = widget.restaurant;
    if (!_invalidCoords(r)) {
      setState(() {
        _lat = r.lat;
        _lng = r.lng;
        _attempted = true;
      });
      return;
    }
    final addr = r.address;
    if (addr == null || addr.isEmpty) {
      setState(() {
        _attempted = true;
      });
      return;
    }
    final pc = _extractUkPostcode(addr);
    if (pc == null) {
      setState(() {
        _attempted = true;
      });
      return;
    }
    setState(() => _loading = true);
    try {
      final detail = await PostcodeApi().lookup(pc);
      final lat = detail.latitude;
      final lng = detail.longitude;
      setState(() {
        _lat = lat;
        _lng = lng;
        _attempted = true;
      });
      // Persist so next load uses DB coordinates too.
      final api = RestaurantSettingsApi(SupabaseClient.instance);
      await api.saveAddress(
        restaurantId: r.id,
        address: r.address ?? detail.formattedAddress(),
        phone: r.phone,
        lat: lat,
        lng: lng,
      );
    } catch (_) {
      setState(() {
        _attempted = true;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && !_attempted) {
      return Container(
        height: 160,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    if ((_lat ?? widget.restaurant.lat) != null &&
        (_lng ?? widget.restaurant.lng) != null) {
      final lat = _lat ?? widget.restaurant.lat!;
      final lng = _lng ?? widget.restaurant.lng!;
      final r = Restaurant(
        id: widget.restaurant.id,
        name: widget.restaurant.name,
        address: widget.restaurant.address,
        phone: widget.restaurant.phone,
        lat: lat,
        lng: lng,
        visible: widget.restaurant.visible,
        createdAt: widget.restaurant.createdAt,
        distanceMeters: widget.restaurant.distanceMeters,
      );
      return RestaurantsMap(
        userLat: lat,
        userLng: lng,
        restaurants: [r],
        height: 240,
      );
    }
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Text('Add a UK postcode in address to auto-pin on the map'),
      ),
    );
  }
}

Future<void> _signOut(BuildContext context, WidgetRef ref) async {
  final result = await ref.read(authControllerProvider.notifier).signOut();
  if (!context.mounted) return;

  if (result.isFailure) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.errorOrNull ?? 'Failed to sign out'),
        backgroundColor: Colors.red,
      ),
    );
  } else {
    context.go('/welcome');
  }
}

Future<void> _openOwnerPayment(BuildContext context) async {
  final user = SupabaseClient.instance.auth.currentUser;
  final uid = user?.id ?? '';
  final email = user?.email ?? '';
  final returnUrl = 'cleardish://payment-complete';
  final url =
      'https://cleardish.co.uk/restaurant-payment/?uid=$uid&email=$email&return_url=$returnUrl';
  final uri = Uri.parse(url);
  await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Opened payment page in browser. Complete and return.'),
    ),
  );
}

class _OwnerPaymentRequired extends StatelessWidget {
  const _OwnerPaymentRequired({
    required this.onPay,
    required this.onRefresh,
    this.message,
  });
  final VoidCallback onPay;
  final VoidCallback onRefresh;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, size: 56),
            const SizedBox(height: 12),
            Text(
              message ??
                  'Please complete the business payment on our website to continue.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onPay,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open payment page'),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('I already paid – refresh'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OwnerEmptyState extends StatelessWidget {
  const _OwnerEmptyState({required this.onCreate, this.message});
  final VoidCallback onCreate;
  final String? message;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.storefront, size: 48),
            const SizedBox(height: 12),
            Text(
              message ?? 'No restaurant assigned to this account',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_business),
              label: const Text('Create my restaurant'),
            )
          ],
        ),
      ),
    );
  }
}

class _DragScrollBehavior extends MaterialScrollBehavior {
  const _DragScrollBehavior();
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}
