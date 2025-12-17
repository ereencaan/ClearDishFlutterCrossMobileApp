import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cleardish/data/sources/supabase_client.dart';
import 'package:cleardish/data/sources/restaurant_settings_api.dart';
import 'package:cleardish/data/sources/menu_api.dart';
import 'package:cleardish/core/utils/result.dart';
import 'package:cleardish/data/models/menu_category.dart';
import 'package:cleardish/data/models/menu_item.dart';
import 'package:cleardish/widgets/app_back_button.dart';

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
  _SetupController(this._settingsApi, this._menuApi)
      : super(const _SetupState()) {
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

  Future<String?> addCategory(String name) async {
    if (state.restaurantId == null) {
      return 'Missing restaurant context';
    }
    final res = await _menuApi.addCategory(
      restaurantId: state.restaurantId!,
      name: name,
    );
    if (res case Failure(:final message)) {
      state = state.copyWith(error: message);
      return message;
    }
    await refreshMenu();
    return null;
  }

  Future<String?> updateCategory({
    required String categoryId,
    required String name,
    int? sortOrder,
  }) async {
    if (state.restaurantId == null) {
      return 'Missing restaurant context';
    }
    final res = await _menuApi.updateCategory(
      id: categoryId,
      name: name,
      sortOrder: sortOrder,
    );
    if (res case Failure(:final message)) {
      state = state.copyWith(error: message);
      return message;
    }
    await refreshMenu();
    return null;
  }

  Future<String?> deleteCategory(String categoryId) async {
    if (state.restaurantId == null) {
      return 'Missing restaurant context';
    }
    final res = await _menuApi.deleteCategory(categoryId);
    if (res case Failure(:final message)) {
      state = state.copyWith(error: message);
      return message;
    }
    await refreshMenu();
    return null;
  }

  Future<String?> addItem({
    String? categoryId,
    required String name,
    double? price,
  }) async {
    if (state.restaurantId == null) {
      return 'Missing restaurant context';
    }
    final res = await _menuApi.addItem(
      restaurantId: state.restaurantId!,
      categoryId: categoryId,
      name: name,
      price: price,
    );
    if (res case Failure(:final message)) {
      state = state.copyWith(error: message);
      return message;
    }
    await refreshMenu();
    return null;
  }

  Future<String?> updateItem({
    required String itemId,
    String? categoryId,
    required String name,
    double? price,
  }) async {
    if (state.restaurantId == null) {
      return 'Missing restaurant context';
    }
    final res = await _menuApi.updateItem(
      id: itemId,
      categoryId: categoryId,
      name: name,
      price: price,
    );
    if (res case Failure(:final message)) {
      state = state.copyWith(error: message);
      return message;
    }
    await refreshMenu();
    return null;
  }

  Future<String?> deleteItem(String itemId) async {
    if (state.restaurantId == null) {
      return 'Missing restaurant context';
    }
    final res = await _menuApi.deleteItem(itemId);
    if (res case Failure(:final message)) {
      state = state.copyWith(error: message);
      return message;
    }
    await refreshMenu();
    return null;
  }
}

class RestaurantSetupScreen extends ConsumerStatefulWidget {
  const RestaurantSetupScreen({super.key});
  @override
  ConsumerState<RestaurantSetupScreen> createState() =>
      _RestaurantSetupScreenState();
}

class _RestaurantSetupScreenState extends ConsumerState<RestaurantSetupScreen> {
  final _addressCtrl = TextEditingController();
  final _categoryNameCtrl = TextEditingController();
  final _itemNameCtrl = TextEditingController();
  final _itemPriceCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();

  @override
  void dispose() {
    _addressCtrl.dispose();
    _categoryNameCtrl.dispose();
    _itemNameCtrl.dispose();
    _itemPriceCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
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
      appBar: AppBar(
        title: const Text('Finish Restaurant Setup'),
        leading: const AppBackButton(
          fallbackRoute: '/home/restaurant/settings',
        ),
      ),
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
              decoration:
                  const InputDecoration(labelText: 'Restaurant Address'),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _latCtrl,
                    decoration: const InputDecoration(labelText: 'Latitude'),
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _lngCtrl,
                    decoration: const InputDecoration(labelText: 'Longitude'),
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
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
                            content:
                                Text('Enter address and valid coordinates'),
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
                  onPressed: () => _showCategoryDialog(context, c),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Category'),
                ),
                OutlinedButton.icon(
                  onPressed: () =>
                      _showItemDialog(context, c, s.categories, null),
                  icon: const Icon(Icons.fastfood),
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
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      tooltip: 'Rename',
                      onPressed: () => _showCategoryDialog(context, c, cat),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Delete',
                      onPressed: () => _confirmDeleteCategory(context, c, cat),
                    ),
                  ],
                ),
              ),
            if (s.items.isNotEmpty) const SizedBox(height: 8),
            if (s.items.isNotEmpty) const Text('Items'),
            for (final it in s.items)
              ListTile(
                dense: true,
                title: Text(it.name),
                subtitle: it.price != null
                    ? Text('£${it.price!.toStringAsFixed(2)}')
                    : null,
                leading: const Icon(Icons.fastfood),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      tooltip: 'Edit item',
                      onPressed: () =>
                          _showItemDialog(context, c, s.categories, it),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Delete',
                      onPressed: () => _confirmDeleteItem(context, c, it),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: canFinish
                  ? () {
                      Navigator.of(context)
                          .pushReplacementNamed('/home/restaurant/settings');
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

  Future<void> _showCategoryDialog(
    BuildContext context,
    _SetupController controller, [
    MenuCategory? category,
  ]) async {
    final isEdit = category != null;
    _categoryNameCtrl.text = category?.name ?? '';
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Edit Category' : 'New Category'),
        content: TextField(
          controller: _categoryNameCtrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Category name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = _categoryNameCtrl.text.trim();
              if (name.isEmpty) return;
              final editingCategory = category;
              final errorMessage = editingCategory != null
                  ? await controller.updateCategory(
                      categoryId: editingCategory.id,
                      name: name,
                    )
                  : await controller.addCategory(name);
              if (!mounted) return;
              if (errorMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '$errorMessage '
                      '(Check Supabase policies / schema for menu tables.)',
                    ),
                  ),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            child: Text(isEdit ? 'Save' : 'Add'),
          ),
        ],
      ),
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEdit ? 'Category updated' : 'Category added'),
        ),
      );
    }
  }

  Future<void> _showItemDialog(
    BuildContext context,
    _SetupController controller,
    List<MenuCategory> categories,
    MenuItem? item,
  ) async {
    final isEdit = item != null;
    _itemNameCtrl.text = item?.name ?? '';
    _itemPriceCtrl.text =
        item?.price != null ? item!.price!.toStringAsFixed(2) : '';
    String? tempCategoryId = item?.categoryId;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(isEdit ? 'Edit Menu Item' : 'New Menu Item'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _itemNameCtrl,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _itemPriceCtrl,
                    decoration: const InputDecoration(labelText: 'Price (£)'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    value: tempCategoryId,
                    onChanged: (value) =>
                        setStateDialog(() => tempCategoryId = value),
                    decoration: const InputDecoration(
                      labelText: 'Category (optional)',
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('No category'),
                      ),
                      ...categories.map(
                        (c) => DropdownMenuItem<String?>(
                          value: c.id,
                          child: Text(c.name),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = _itemNameCtrl.text.trim();
                    if (name.isEmpty) return;
                    final price = double.tryParse(_itemPriceCtrl.text.trim());
                    final editingItem = item;
                    final errorMessage = editingItem != null
                        ? await controller.updateItem(
                            itemId: editingItem.id,
                            name: name,
                            price: price,
                            categoryId: tempCategoryId,
                          )
                        : await controller.addItem(
                            name: name,
                            price: price,
                            categoryId: tempCategoryId,
                          );
                    if (!mounted) return;
                    if (errorMessage != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '$errorMessage '
                            '(Check Supabase policies / schema for menu tables.)',
                          ),
                        ),
                      );
                      return;
                    }
                    Navigator.pop(context, true);
                  },
                  child: Text(isEdit ? 'Save' : 'Add'),
                ),
              ],
            );
          },
        );
      },
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEdit ? 'Item updated' : 'Item added'),
        ),
      );
    }
  }

  Future<void> _confirmDeleteCategory(
    BuildContext context,
    _SetupController controller,
    MenuCategory category,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
          'Delete "${category.name}"? Items in this category will be left without a category.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final errorMessage = await controller.deleteCategory(category.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMessage ??
                'Deleted "${category.name}"'
                    '\n(RLS policies control who can edit these rows.)',
          ),
        ),
      );
    }
  }

  Future<void> _confirmDeleteItem(
    BuildContext context,
    _SetupController controller,
    MenuItem item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Delete "${item.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final errorMessage = await controller.deleteItem(item.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMessage ??
                'Deleted "${item.name}"'
                    '\n(RLS policies control who can edit these rows.)',
          ),
        ),
      );
    }
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
