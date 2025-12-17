import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import 'package:cleardish/features/profile/controllers/profile_controller.dart';
import 'package:cleardish/features/auth/controllers/auth_controller.dart';
import 'package:cleardish/core/utils/result.dart';
import 'package:cleardish/data/models/allergen.dart';
import 'package:cleardish/data/models/menu_category.dart';
import 'package:cleardish/data/models/menu_item.dart';
import 'package:cleardish/data/models/promotion.dart';
import 'package:cleardish/data/models/restaurant.dart';
import 'package:cleardish/data/models/restaurant_visitor.dart';
import 'package:cleardish/data/sources/menu_api.dart';
import 'package:cleardish/data/sources/restaurant_settings_api.dart';
import 'package:cleardish/data/sources/restaurant_visit_api.dart';
import 'package:cleardish/data/sources/supabase_client.dart';
import 'package:cleardish/widgets/app_back_button.dart';
import 'package:cleardish/widgets/app_button.dart';
import 'package:cleardish/widgets/chips_filter.dart';

/// Profile screen
///
/// Allows users to view and edit their profile, allergens, and diets.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  bool _isAdmin = false;
  bool _isRestaurant = false;

  @override
  void initState() {
    super.initState();
    final user = supa.Supabase.instance.client.auth.currentUser;
    final role = user?.userMetadata?['role'] as String?;
    _isAdmin = role == 'admin';
    _isRestaurant = role == 'restaurant';
    if (!_isAdmin) {
      // Defer provider mutations until after first frame to avoid
      // "modify provider while building" errors on web.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadProfile();
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = supa.Supabase.instance.client.auth.currentUser;
    if (user != null) {
      await ref.read(profileControllerProvider.notifier).loadProfile(user.id);
      final profile = ref.read(profileControllerProvider).profile;
      if (profile?.fullName != null) {
        _nameController.text = profile!.fullName!;
      }
    }
  }

  Future<void> _handleSave() async {
    final user = supa.Supabase.instance.client.auth.currentUser;
    if (user == null) {
      context.go('/login');
      return;
    }

    final profileController = ref.read(profileControllerProvider.notifier);
    final profile = ref.read(profileControllerProvider).profile;

    if (profile == null) {
      return;
    }

    final updatedProfile = profile.copyWith(
      fullName: _nameController.text.trim().isEmpty
          ? null
          : _nameController.text.trim(),
    );

    final result = await profileController.saveProfile(updatedProfile);

    if (!mounted) return;

    if (result.isFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorOrNull ?? 'Failed to save profile'),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _handleLogout() async {
    final result = await ref.read(authControllerProvider.notifier).signOut();
    if (!mounted) return;

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

  @override
  Widget build(BuildContext context) {
    final user = supa.Supabase.instance.client.auth.currentUser;

    // Admin profile: simple overview and actions, no onboarding fields
    if (_isAdmin) {
      return Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(fallbackRoute: '/admin'),
          title: const Text('Admin Profile'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.verified_user),
                  title: Text(user?.email ?? 'Admin'),
                  subtitle: const Text('Role: admin'),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go('/admin'),
                child: const Text('Open Admin Dashboard'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _handleLogout,
                child: const Text('Sign Out'),
              ),
            ],
          ),
        ),
      );
    }

    if (_isRestaurant) {
      return const _RestaurantOwnerProfilePanel();
    }

    final profileState = ref.watch(profileControllerProvider);
    if (profileState.isLoading && profileState.profile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final profile = profileState.profile;
    final hasPendingAllergen = profileState.pendingAllergenRequest != null;
    final hasPendingDiet = profileState.pendingDietRequest != null;
    final disableAllergenSelection =
        hasPendingAllergen || profileState.isSubmittingChange;
    final disableDietSelection =
        hasPendingDiet || profileState.isSubmittingChange;
    final allergenItems =
        Allergen.standardAllergens.map((a) => a.name).toList();
    final dietItems = Allergen.standardDiets.map((d) => d.name).toList();

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallbackRoute: '/home'),
        title: const Text('Profile'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              ChipsFilter(
                label: 'Allergens',
                items: allergenItems,
                selectedItems: profile?.allergens ?? [],
                enabled: !disableAllergenSelection,
                onSelectionChanged: (selected) async {
                  if (user != null && profile != null) {
                    await _submitAllergenChange(
                      userId: user.id,
                      selected: selected,
                      current: profile.allergens,
                    );
                  }
                },
              ),
              if (hasPendingAllergen) ...[
                const SizedBox(height: 12),
                _PendingApprovalBanner(
                  title: 'Allergen update awaiting admin approval',
                  requestedValues:
                      profileState.pendingAllergenRequest!.requestedValues,
                ),
              ],
              const SizedBox(height: 24),
              ChipsFilter(
                label: 'Dietary Preferences',
                items: dietItems,
                selectedItems: profile?.diets ?? [],
                enabled: !disableDietSelection,
                onSelectionChanged: (selected) async {
                  if (user != null && profile != null) {
                    await _submitDietChange(
                      userId: user.id,
                      selected: selected,
                      current: profile.diets,
                    );
                  }
                },
              ),
              if (hasPendingDiet) ...[
                const SizedBox(height: 12),
                _PendingApprovalBanner(
                  title: 'Diet preference update awaiting admin approval',
                  requestedValues:
                      profileState.pendingDietRequest!.requestedValues,
                ),
              ],
              const SizedBox(height: 32),
              AppButton(
                label: 'Save Profile',
                isLoading: profileState.isSaving,
                onPressed: _handleSave,
              ),
              const SizedBox(height: 16),
              AppButton(
                label: 'Sign Out',
                isOutlined: true,
                onPressed: _handleLogout,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitAllergenChange({
    required String userId,
    required List<String> selected,
    required List<String> current,
  }) async {
    if (_hasSameValues(selected, current)) {
      _showSnack('No changes detected.');
      return;
    }

    // First-time setup: if there is no current value, write directly without approval
    if (current.isEmpty) {
      final direct = await ref
          .read(profileControllerProvider.notifier)
          .updateAllergens(userId, selected);
      if (!mounted) return;
      if (direct.isFailure) {
        _showSnack(
          direct.errorOrNull ?? 'Failed to save allergens',
          isError: true,
        );
      } else {
        _showSnack('Allergens saved.');
      }
      return;
    }

    final result = await ref
        .read(profileControllerProvider.notifier)
        .requestAllergenChange(userId, selected);
    if (!mounted) return;
    if (result.isFailure) {
      _showSnack(
        result.errorOrNull ?? 'Failed to submit allergen update request',
        isError: true,
      );
    } else {
      _showSnack('Allergen update sent to admin for approval.');
    }
  }

  Future<void> _submitDietChange({
    required String userId,
    required List<String> selected,
    required List<String> current,
  }) async {
    if (_hasSameValues(selected, current)) {
      _showSnack('No changes detected.');
      return;
    }
    // First-time setup: save directly if no current value
    if (current.isEmpty) {
      final direct = await ref
          .read(profileControllerProvider.notifier)
          .updateDiets(userId, selected);
      if (!mounted) return;
      if (direct.isFailure) {
        _showSnack(
          direct.errorOrNull ?? 'Failed to save dietary preferences',
          isError: true,
        );
      } else {
        _showSnack('Dietary preferences saved.');
      }
      return;
    }
    final result = await ref
        .read(profileControllerProvider.notifier)
        .requestDietChange(userId, selected);
    if (!mounted) return;
    if (result.isFailure) {
      _showSnack(
        result.errorOrNull ?? 'Failed to submit dietary update request',
        isError: true,
      );
    } else {
      _showSnack('Diet preference update sent to admin for approval.');
    }
  }

  bool _hasSameValues(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    final setA = a.toSet();
    final setB = b.toSet();
    if (setA.length != setB.length) return false;
    for (final value in setA) {
      if (!setB.contains(value)) return false;
    }
    return true;
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }
}

class _PendingApprovalBanner extends StatelessWidget {
  const _PendingApprovalBanner({
    required this.title,
    required this.requestedValues,
  });

  final String title;
  final List<String> requestedValues;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Card(
      color: color.secondaryContainer.withOpacity(0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.hourglass_top, color: color.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (requestedValues.isEmpty)
              Text(
                'Requested change: clear all selections',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: requestedValues
                    .map(
                      (value) => Chip(
                        label: Text(value),
                        backgroundColor: color.primary.withOpacity(0.15),
                        side: BorderSide(color: color.primary),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

final restaurantOwnerDataProvider =
    FutureProvider.autoDispose<_RestaurantOwnerData>((ref) async {
  final settingsApi = RestaurantSettingsApi(SupabaseClient.instance);
  final menuApi = MenuApi(SupabaseClient.instance);
  final visitApi = RestaurantVisitApi(SupabaseClient.instance);

  final restaurantResult = await settingsApi.getMyRestaurant();
  if (restaurantResult.isFailure) {
    throw Exception(
        restaurantResult.errorOrNull ?? 'Failed to load restaurant');
  }

  final restaurant = restaurantResult.dataOrNull!;
  final categoriesResult = await menuApi.getCategories(restaurant.id);
  if (categoriesResult.isFailure) {
    throw Exception(
        categoriesResult.errorOrNull ?? 'Failed to load categories');
  }
  final itemsResult = await menuApi.getMenuItems(restaurant.id);
  if (itemsResult.isFailure) {
    throw Exception(itemsResult.errorOrNull ?? 'Failed to load menu');
  }
  final visitorsResult = await visitApi.getRecentVisitors(restaurant.id);
  if (visitorsResult.isFailure) {
    throw Exception(visitorsResult.errorOrNull ?? 'Failed to load visitors');
  }
  final promotionsResult = await settingsApi.getPromotions(restaurant.id);
  if (promotionsResult.isFailure) {
    throw Exception(
        promotionsResult.errorOrNull ?? 'Failed to load promotions');
  }

  return _RestaurantOwnerData(
    restaurant: restaurant,
    categories: categoriesResult.dataOrNull ?? const [],
    items: itemsResult.dataOrNull ?? const [],
    visitors: visitorsResult.dataOrNull ?? const [],
    promotions: promotionsResult.dataOrNull ?? const [],
  );
});

class _RestaurantOwnerProfilePanel extends ConsumerStatefulWidget {
  const _RestaurantOwnerProfilePanel();

  @override
  ConsumerState<_RestaurantOwnerProfilePanel> createState() =>
      _RestaurantOwnerProfilePanelState();
}

class _RestaurantOwnerProfilePanelState
    extends ConsumerState<_RestaurantOwnerProfilePanel> {
  late final RestaurantSettingsApi _settingsApi;
  late final MenuApi _menuApi;
  final _promoTitleCtrl = TextEditingController();
  final _promoDescCtrl = TextEditingController();
  final _promoPercentCtrl = TextEditingController(text: '10');

  @override
  void initState() {
    super.initState();
    _settingsApi = RestaurantSettingsApi(SupabaseClient.instance);
    _menuApi = MenuApi(SupabaseClient.instance);
  }

  @override
  void dispose() {
    _promoTitleCtrl.dispose();
    _promoDescCtrl.dispose();
    _promoPercentCtrl.dispose();
    super.dispose();
  }

  Future<void> _refreshOwnerData() async {
    ref.invalidate(restaurantOwnerDataProvider);
    await ref.read(restaurantOwnerDataProvider.future);
  }

  Future<void> _signOut() async {
    final result = await ref.read(authControllerProvider.notifier).signOut();
    if (!mounted) return;
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

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(restaurantOwnerDataProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant Profile'),
        leading: const AppBackButton(fallbackRoute: '/home/restaurants'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: dataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load: $e')),
        data: (data) {
          return RefreshIndicator(
            onRefresh: _refreshOwnerData,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildInfoCard(context, data.restaurant),
                const SizedBox(height: 16),
                _buildMenuCard(context, data),
                const SizedBox(height: 16),
                _buildVisitorsCard(context, data.visitors),
                const SizedBox(height: 16),
                _buildBadgesCard(context, data.restaurant.id),
                const SizedBox(height: 16),
                _buildPromotionsCard(
                    context, data.restaurant.id, data.promotions),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, Restaurant restaurant) {
    return Card(
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
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: () => context.go('/home/restaurant/settings'),
                  icon: const Icon(Icons.edit_location_alt),
                  label: const Text('Edit Address & Contact'),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go('/home/restaurant/setup'),
                  icon: const Icon(Icons.menu_book),
                  label: const Text('Manage Menu'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, _RestaurantOwnerData data) {
    final uncategorized =
        data.items.where((item) => item.categoryId == null).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Menu',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _refreshOwnerData,
                  tooltip: 'Refresh menu',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () =>
                      _showAddCategoryDialog(context, data.restaurant.id),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Category'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _showAddItemDialog(
                    context,
                    data.restaurant.id,
                    data.categories,
                  ),
                  icon: const Icon(Icons.fastfood),
                  label: const Text('Add Item'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (data.categories.isEmpty && data.items.isEmpty)
              const Text('No menu items yet.'),
            for (final category in data.categories)
              ExpansionTile(
                title: Text(category.name),
                children: data.items
                    .where((item) => item.categoryId == category.id)
                    .map(
                      (item) => ListTile(
                        title: Text(item.name),
                        subtitle: item.price != null
                            ? Text('£${item.price!.toStringAsFixed(2)}')
                            : null,
                      ),
                    )
                    .toList(),
              ),
            if (uncategorized.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Uncategorized'),
              ...uncategorized.map(
                (item) => ListTile(
                  title: Text(item.name),
                  subtitle: item.price != null
                      ? Text('£${item.price!.toStringAsFixed(2)}')
                      : null,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildVisitorsCard(
      BuildContext context, List<RestaurantVisitor> visitors) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Visitors',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (visitors.isEmpty)
              const Text('Your visitors will appear here once they browse.'),
            for (final v in visitors)
              ListTile(
                dense: true,
                leading: const Icon(Icons.person_outline),
                title: Text(v.fullName ?? 'Guest'),
                subtitle: Text(
                  '${v.visitedAt.toLocal()}'.split('.').first,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgesCard(BuildContext context, String restaurantId) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Badges',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton(
                  onPressed: () async {
                    final now = DateTime.now();
                    final start = DateTime(now.year, now.month, now.day)
                        .subtract(Duration(days: now.weekday - 1));
                    final end = start.add(const Duration(days: 6));
                    final result = await _settingsApi.createBadge(
                      restaurantId: restaurantId,
                      type: 'weekly',
                      periodStart: start,
                      periodEnd: end,
                    );
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          result.isFailure
                              ? (result.errorOrNull ?? 'Failed to add badge')
                              : 'Weekly badge added',
                        ),
                      ),
                    );
                  },
                  child: const Text('Add Weekly Badge'),
                ),
                FilledButton(
                  onPressed: () async {
                    final now = DateTime.now();
                    final start = DateTime(now.year, now.month, 1);
                    final end = DateTime(now.year, now.month + 1, 1)
                        .subtract(const Duration(days: 1));
                    final result = await _settingsApi.createBadge(
                      restaurantId: restaurantId,
                      type: 'monthly',
                      periodStart: start,
                      periodEnd: end,
                    );
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          result.isFailure
                              ? (result.errorOrNull ?? 'Failed to add badge')
                              : 'Monthly badge added',
                        ),
                      ),
                    );
                  },
                  child: const Text('Add Monthly Badge'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromotionsCard(
      BuildContext context, String restaurantId, List<Promotion> promotions) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Promotions & Discounts',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _refreshOwnerData,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (promotions.isEmpty) const Text('No active promotions.'),
            for (final promo in promotions)
              ListTile(
                title: Text(promo.title),
                subtitle: Text(
                  'Until ${promo.endsAt.toLocal()} • ${promo.percentOff.toStringAsFixed(1)}% off',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final result = await _settingsApi.deletePromotion(promo.id);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          result.isFailure
                              ? (result.errorOrNull ??
                                  'Failed to remove promotion')
                              : 'Promotion removed',
                        ),
                      ),
                    );
                    await _refreshOwnerData();
                  },
                ),
              ),
            const Divider(height: 32),
            TextField(
              controller: _promoTitleCtrl,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _promoDescCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _promoPercentCtrl,
              decoration:
                  const InputDecoration(labelText: 'Percent off (0-100)'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () async {
                final percent =
                    double.tryParse(_promoPercentCtrl.text.trim()) ?? 0;
                final result = await _settingsApi.createPromotion(
                  restaurantId: restaurantId,
                  title: _promoTitleCtrl.text.trim(),
                  description: _promoDescCtrl.text.trim().isEmpty
                      ? null
                      : _promoDescCtrl.text.trim(),
                  percentOff: percent,
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      result.isFailure
                          ? (result.errorOrNull ?? 'Failed to create promotion')
                          : 'Promotion created',
                    ),
                  ),
                );
                _promoTitleCtrl.clear();
                _promoDescCtrl.clear();
                _promoPercentCtrl.text = '10';
                await _refreshOwnerData();
              },
              child: const Text('Create / Update Promotion'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddCategoryDialog(
      BuildContext context, String restaurantId) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Category'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Category name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              final result = await _menuApi.addCategory(
                restaurantId: restaurantId,
                name: name,
              );
              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    result.isFailure
                        ? (result.errorOrNull ?? 'Failed to add category')
                        : 'Category added',
                  ),
                ),
              );
              await _refreshOwnerData();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddItemDialog(
    BuildContext context,
    String restaurantId,
    List<MenuCategory> categories,
  ) async {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    String? categoryId = categories.isNotEmpty ? categories.first.id : null;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Menu Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Item name'),
            ),
            TextField(
              controller: priceCtrl,
              decoration: const InputDecoration(labelText: 'Price (£)'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            DropdownButtonFormField<String>(
              value: categoryId,
              items: categories
                  .map(
                    (c) => DropdownMenuItem(
                      value: c.id,
                      child: Text(c.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) => categoryId = value,
              decoration:
                  const InputDecoration(labelText: 'Category (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final price = double.tryParse(priceCtrl.text.trim());
              if (name.isEmpty) return;
              final result = await _menuApi.addItem(
                restaurantId: restaurantId,
                categoryId: categoryId,
                name: name,
                price: price,
              );
              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    result.isFailure
                        ? (result.errorOrNull ?? 'Failed to add item')
                        : 'Menu item added',
                  ),
                ),
              );
              await _refreshOwnerData();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _RestaurantOwnerData {
  const _RestaurantOwnerData({
    required this.restaurant,
    required this.categories,
    required this.items,
    required this.visitors,
    required this.promotions,
  });

  final Restaurant restaurant;
  final List<MenuCategory> categories;
  final List<MenuItem> items;
  final List<RestaurantVisitor> visitors;
  final List<Promotion> promotions;
}
