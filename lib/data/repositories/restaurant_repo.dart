import 'package:cleardish/core/utils/result.dart';
import 'package:cleardish/data/models/restaurant.dart';
import 'package:cleardish/data/sources/restaurant_api.dart';
import 'package:cleardish/data/sources/supabase_client.dart';

/// Restaurant repository
///
/// Provides restaurant data operations.
class RestaurantRepo {
  RestaurantRepo() : _api = RestaurantApi(SupabaseClient.instance);

  final RestaurantApi _api;

  /// Gets all visible restaurants
  Future<Result<List<Restaurant>>> getRestaurants() async {
    return _api.getRestaurants();
  }

  /// Gets a single restaurant by ID
  Future<Result<Restaurant>> getRestaurant(String id) async {
    return _api.getRestaurant(id);
  }

  /// Create
  Future<Result<Restaurant>> createRestaurant(Restaurant r) {
    return _api.createRestaurant(r);
  }

  /// Update
  Future<Result<Restaurant>> updateRestaurant(Restaurant r) {
    return _api.updateRestaurant(r);
  }

  /// Delete
  Future<Result<void>> deleteRestaurant(String id) {
    return _api.deleteRestaurant(id);
  }

  /// Terminate partnership
  Future<Result<void>> terminateRestaurant(String id) {
    return _api.terminateRestaurant(id);
  }
}
