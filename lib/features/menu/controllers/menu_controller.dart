import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cleardish/data/repositories/menu_repo.dart';
import 'package:cleardish/data/repositories/profile_repo.dart';
import 'package:cleardish/data/models/menu_item.dart';
import 'package:cleardish/core/utils/result.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Menu repository provider
final menuRepoProvider = Provider<MenuRepo>((ref) {
  return MenuRepo();
});

/// Menu controller state
class MenuState {
  const MenuState({
    this.isLoading = false,
    this.error,
    this.menuItems = const [],
    this.safeOnly = false,
    this.hiddenCount = 0,
  });

  final bool isLoading;
  final String? error;
  final List<MenuItem> menuItems;
  final bool safeOnly;
  final int hiddenCount;

  MenuState copyWith({
    bool? isLoading,
    String? error,
    List<MenuItem>? menuItems,
    bool? safeOnly,
    int? hiddenCount,
  }) {
    return MenuState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      menuItems: menuItems ?? this.menuItems,
      safeOnly: safeOnly ?? this.safeOnly,
      hiddenCount: hiddenCount ?? this.hiddenCount,
    );
  }
}

/// Menu controller
class MenuController extends StateNotifier<MenuState> {
  MenuController(
    this._menuRepo,
    this._profileRepo,
    this.restaurantId,
  ) : super(const MenuState()) {
    loadMenu();
  }

  final MenuRepo _menuRepo;
  final ProfileRepo _profileRepo;
  final String restaurantId;

  /// Loads menu for restaurant
  Future<void> loadMenu() async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _menuRepo.getMenuByRestaurant(restaurantId);
    if (result.isFailure) {
      state = state.copyWith(
        isLoading: false,
        error: result.errorOrNull,
      );
      return;
    }

    final menuMap = result.dataOrNull!;
    final allItems = menuMap.values.expand((items) => items).toList();

    state = state.copyWith(
      isLoading: false,
      menuItems: allItems,
    );
    _updateFilter();
  }

  /// Toggles safe-only filter
  void toggleSafeOnly() {
    state = state.copyWith(safeOnly: !state.safeOnly);
    _updateFilter();
  }

  void _updateFilter() {
    if (!state.safeOnly) {
      state = state.copyWith(hiddenCount: 0);
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return;
    }

    // Get user profile allergens
    _profileRepo.getProfile(user.id).then((profileResult) {
      if (profileResult.isFailure || profileResult.dataOrNull == null) {
        return;
      }

      final userAllergens = profileResult.dataOrNull!.allergens;
      if (userAllergens.isEmpty) {
        state = state.copyWith(hiddenCount: 0);
        return;
      }

      // Count items that contain user allergens
      final hiddenCount = state.menuItems
          .where((item) => item.containsAllergens(userAllergens))
          .length;

      state = state.copyWith(hiddenCount: hiddenCount);
    });
  }

  /// Gets filtered menu items based on safe-only toggle
  List<MenuItem> getFilteredItems(List<String> userAllergens) {
    if (!state.safeOnly || userAllergens.isEmpty) {
      return state.menuItems;
    }

    return state.menuItems
        .where((item) => !item.containsAllergens(userAllergens))
        .toList();
  }
}

/// Menu controller provider factory
final menuControllerProvider = StateNotifierProvider.family<
    MenuController, MenuState, String>((ref, restaurantId) {
  return MenuController(
    ref.watch(menuRepoProvider),
    ref.watch(profileRepoProvider),
    restaurantId,
  );
});

