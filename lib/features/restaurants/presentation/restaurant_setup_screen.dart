import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cleardish/data/sources/supabase_client.dart';
import 'package:cleardish/data/sources/restaurant_settings_api.dart';
import 'package:cleardish/data/sources/menu_api.dart';
import 'package:cleardish/core/utils/result.dart';
import 'package:cleardish/data/models/menu_category.dart';
import 'package:cleardish/data/models/menu_item.dart';

final _setupProvider =
    StateNotifierProvider<_SetupController, _SetupState>((ref) {
  final client = SupabaseClient.instance;
  return _SetupController(
    RestaurantSettingsApi(client),
    MenuApi(client),
  );
});

class _SetupState {
  const _SetupState({
    this.isLoading = false,
    this.error,
    this.restaurantId,
    this.address,
    this.lat,
    this.lng,
    this.categories = const [],
    this.items = const [],
  });
  final bool isLoading;
  final String? error;
  final String? restaurantId;
  final String? address;
  final double? lat;
  final double? lng;
  final List<MenuCategory> categories;
  final List<MenuItem> items;

  bool get hasLocation => address != null && lat != null && lng != null;
  bool get hasMenu => items.isNotEmpty;

  _SetupState copyWith({
    bool? isLoading,
    String? error,
    String? restaurantId,
    String? address,
    double? lat,
    double? lng,
    List<MenuCategory>? categories,
    List<MenuItem>? items,
  }) {
    return _SetupState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      restaurantId: restaurantId ?? this.restaurantId,
      address: address ?? this.address,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      categories: categories ?? this.categories,
      items: items ?? this.items,
    );
  }
}

class _SetupController extends StateNotifier<_SetupState> {
  _SetupController(this._settingsApi, this._menuApi) : super(const _SetupState()) {
    _load();
  }
  final RestaurantSettingsApi _settingsApi;
  final MenuApi _menuApi;

  Future<void> _load() async {
    state = state.copyWith(isLoading: true, error: null);
    final r = await _settingsApi.getMyRestaurant();
    if (r is Failure) {
      state = state.copyWith(isLoading: false, error: (r as Failure).message);
      return;
    }
    final restaurant = (r as Success).data;
    final categoriesRes = await _menuApi.getCategories(restaurant.id);
    final itemsRes = await _menuApi.getMenuItems(restaurant.id);
    state = state.copyWith(
      isLoading: false,
      restaurantId: restaurant.id,
      address: restaurant.address,
      lat: restaurant.lat,
      lng: restaurant.lng,
      categories: categoriesRes.dataOrNull ?? const [],
      items: itemsRes.dataOrNull ?? const [],
    );
  }

  Future<void> saveLocation(String address, double lat, double lng) async {
    if (state.restaurantId == null) return;
    state = state.copyWith(isLoading: true, error: null);
    final res = await _settingsApi.saveAddress(
      restaurantId: state.restaurantId!,
      address: address,
      lat: lat,
      lng: lng,
    );
    if (res is Success) {
      final r = (res as Success).data;
      state = state.copyWith(
        isLoading: false,
        address: r.address,
        lat: r.lat,
        lng: r.lng,
      );
    } else {
      state = state.copyWith(isLoading: false, error: (res as Failure).message);
    }
  }

  Future<void> refreshMenu() async {
    if (state.restaurantId == null) return;
    final categoriesRes = await _menuApi.getCategories(state.restaurantId!);
    final itemsRes = await _menuApi.getMenuItems(state.restaurantId!);
    state = state.copyWith(
      categories: categoriesRes.dataOrNull ?? const [],
      items: itemsRes.dataOrNull ?? const [],
    );
  }

  Future<void> addCategory(String name) async {
    if (state.restaurantId == null) return;
    final res = await _menuApi.addCategory(
      restaurantId: state.restaurantId!,
      name: name,
    );
    if (res is Failure) return;
    await refreshMenu();
  }

  Future<void> addItem({
    String? categoryId,
    required String name,
    double? price,
  }) async {
    if (state.restaurantId == null) return;
    final res = await _menuApi.addItem(
      restaurantId: state.restaurantId!,
      categoryId: categoryId,
      name: name,
      price: price,
    );
    if (res is Failure) return;
    await refreshMenu();
  }
}

class RestaurantSetupScreen extends ConsumerStatefulWidget {
  const RestaurantSetupScreen({super.key});
  @override
  ConsumerState<RestaurantSetupScreen> createState() => _RestaurantSetupScreenState();
}

class _RestaurantSetupScreenState extends ConsumerState<RestaurantSetupScreen> {
  final _addressCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  final _catNameCtrl = TextEditingController();
  final _itemNameCtrl = TextEditingController();
  final _itemPriceCtrl = TextEditingController();

  @override
  void dispose() {
    _addressCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _catNameCtrl.dispose();
    _itemNameCtrl.dispose();
    _itemPriceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(_setupProvider);
    final c = ref.read(_setupProvider.notifier);
    final canFinish = s.hasLocation && s.hasMenu;

    // Prefill once
    if (_addressCtrl.text.isEmpty && s.address != null) {
      _addressCtrl.text = s.address!;
    }
    if (_latCtrl.text.isEmpty && s.lat != null) {
      _latCtrl.text = s.lat!.toStringAsFixed(6);
    }
    if (_lngCtrl.text.isEmpty && s.lng != null) {
      _lngCtrl.text = s.lng!.toStringAsFixed(6);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Finish Restaurant Setup')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StepHeader(
              title: 'Step 1 — Address & Location',
              done: s.hasLocation,
            ),
            TextField(
              controller: _addressCtrl,
              decoration: const InputDecoration(labelText: 'Restaurant Address'),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _latCtrl,
                    decoration: const InputDecoration(labelText: 'Latitude'),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _lngCtrl,
                    decoration: const InputDecoration(labelText: 'Longitude'),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: s.restaurantId == null
                  ? null
                  : () async {
                      final lat = double.tryParse(_latCtrl.text.trim());
                      final lng = double.tryParse(_lngCtrl.text.trim());
                      final addr = _addressCtrl.text.trim();
                      if (addr.isEmpty || lat == null || lng == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Enter address and valid coordinates'),
                          ),
                        );
                        return;
                      }
                      await c.saveLocation(addr, lat, lng);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Location saved')),
                      );
                    },
              child: const Text('Save Location'),
            ),
            const Divider(height: 32),

            _StepHeader(
              title: 'Step 2 — Create Your Menu',
              done: s.hasMenu,
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    _catNameCtrl.clear();
                    await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('New Category'),
                        content: TextField(
                          controller: _catNameCtrl,
                          decoration: const InputDecoration(labelText: 'Name'),
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                          ElevatedButton(
                              onPressed: () async {
                                final name = _catNameCtrl.text.trim();
                                if (name.isEmpty) return;
                                await c.addCategory(name);
                                if (!mounted) return;
                                Navigator.pop(context);
                              },
                              child: const Text('Add')),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Category'),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    _itemNameCtrl.clear();
                    _itemPriceCtrl.clear();
                    await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('New Menu Item'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              controller: _itemNameCtrl,
                              decoration: const InputDecoration(labelText: 'Name'),
                            ),
                            TextField(
                              controller: _itemPriceCtrl,
                              decoration: const InputDecoration(labelText: 'Price (£)'),
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                          ElevatedButton(
                              onPressed: () async {
                                final name = _itemNameCtrl.text.trim();
                                final price = double.tryParse(_itemPriceCtrl.text.trim());
                                if (name.isEmpty) return;
                                await c.addItem(name: name, price: price);
                                if (!mounted) return;
                                Navigator.pop(context);
                              },
                              child: const Text('Add')),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (s.categories.isNotEmpty) const Text('Categories'),
            for (final cat in s.categories)
              ListTile(
                dense: true,
                title: Text(cat.name),
                leading: const Icon(Icons.folder),
              ),
            if (s.items.isNotEmpty) const SizedBox(height: 8),
            if (s.items.isNotEmpty) const Text('Items'),
            for (final it in s.items)
              ListTile(
                dense: true,
                title: Text(it.name),
                subtitle: it.price != null ? Text('£${it.price!.toStringAsFixed(2)}') : null,
                leading: const Icon(Icons.fastfood),
              ),

            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: canFinish
                  ? () {
                      Navigator.of(context).pushReplacementNamed('/home/restaurant/settings');
                    }
                  : null,
              icon: const Icon(Icons.check_circle),
              label: const Text('Finish Setup'),
            ),
            if (s.error != null) ...[
              const SizedBox(height: 12),
              Text(s.error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.title, required this.done});
  final String title;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(done ? Icons.check_circle : Icons.radio_button_unchecked,
            color: done ? Colors.green : Colors.grey),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}


