import 'package:cleardish/core/utils/result.dart';
import 'package:cleardish/data/models/restaurant.dart';
import 'package:cleardish/data/sources/supabase_client.dart';

/// Restaurant API
///
/// Handles restaurant data operations with Supabase.
class RestaurantApi {
  RestaurantApi(this._client);
  final SupabaseClient _client;

  /// Gets all visible restaurants
  Future<Result<List<Restaurant>>> getRestaurants() async {
    try {
      final response = await _client.supabaseClient.client.from('restaurants').select().eq(
            'visible',
            true,
          ).order('name');

      final restaurants = (response as List)
          .map((json) => Restaurant.fromMap(json as Map<String, dynamic>))
          .toList();

      return Success(restaurants);
    } catch (e) {
      return Failure('Failed to fetch restaurants: ${e.toString()}');
    }
  }

  /// Gets a single restaurant by ID
  Future<Result<Restaurant>> getRestaurant(String id) async {
    try {
      final response = await _client.supabaseClient.client.from('restaurants').select().eq(
            'id',
            id,
          ).single();

      final restaurant = Restaurant.fromMap(
        response,
      );

      return Success(restaurant);
    } catch (e) {
      return Failure('Failed to fetch restaurant: ${e.toString()}');
    }
  }
}
