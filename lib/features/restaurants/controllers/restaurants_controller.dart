import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cleardish/data/repositories/restaurant_repo.dart';
import 'package:cleardish/data/models/restaurant.dart';
import 'package:cleardish/core/utils/result.dart';

/// Restaurant repository provider
final restaurantRepoProvider = Provider<RestaurantRepo>((ref) {
  return RestaurantRepo();
});

/// Restaurants controller state
class RestaurantsState {
  const RestaurantsState({
    this.isLoading = false,
    this.error,
    this.restaurants = const [],
    this.searchQuery = '',
  });

  final bool isLoading;
  final String? error;
  final List<Restaurant> restaurants;
  final String searchQuery;

  RestaurantsState copyWith({
    bool? isLoading,
    String? error,
    List<Restaurant>? restaurants,
    String? searchQuery,
  }) {
    return RestaurantsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      restaurants: restaurants ?? this.restaurants,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  /// Filtered restaurants based on search query
  List<Restaurant> get filteredRestaurants {
    if (searchQuery.isEmpty) {
      return restaurants;
    }
    final query = searchQuery.toLowerCase();
    return restaurants.where((restaurant) {
      return restaurant.name.toLowerCase().contains(query) ||
          (restaurant.address?.toLowerCase().contains(query) ?? false);
    }).toList();
  }
}

/// Restaurants controller
class RestaurantsController extends StateNotifier<RestaurantsState> {
  RestaurantsController(this._restaurantRepo) : super(const RestaurantsState()) {
    loadRestaurants();
  }

  final RestaurantRepo _restaurantRepo;

  /// Loads all restaurants
  Future<void> loadRestaurants() async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _restaurantRepo.getRestaurants();
    state = state.copyWith(
      isLoading: false,
      error: result.isFailure ? result.errorOrNull : null,
      restaurants: result.dataOrNull ?? [],
    );
  }

  /// Updates search query
  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }
}

/// Restaurants controller provider
final restaurantsControllerProvider =
    StateNotifierProvider<RestaurantsController, RestaurantsState>((ref) {
  return RestaurantsController(ref.watch(restaurantRepoProvider));
});

