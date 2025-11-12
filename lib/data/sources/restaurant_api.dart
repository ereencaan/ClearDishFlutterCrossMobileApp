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

  /// Gets nearby restaurants using RPC
  Future<Result<List<Restaurant>>> getNearbyRestaurants({
    required double lat,
    required double lng,
    double radiusKm = 5,
  }) async {
    try {
      final response = await _client.supabaseClient.client.rpc(
        'restaurants_nearby',
        params: {
          'p_lat': lat,
          'p_lng': lng,
          'p_radius_km': radiusKm,
        },
      );

      final restaurants = (response as List)
          .map((json) => Restaurant.fromMap(json as Map<String, dynamic>))
          .toList();

      return Success(restaurants);
    } catch (e) {
      return Failure('Failed to fetch nearby restaurants: ${e.toString()}');
    }
  }

  /// Creates a restaurant
  Future<Result<Restaurant>> createRestaurant(Restaurant r) async {
    try {
      final response = await _client.supabaseClient.client
          .from('restaurants')
          .insert({
        'name': r.name,
        'address': r.address,
        'lat': r.lat,
        'lng': r.lng,
        'visible': r.visible,
      }).select().single();
      return Success(Restaurant.fromMap(response));
    } catch (e) {
      return Failure('Failed to create restaurant: ${e.toString()}');
    }
  }

  /// Updates a restaurant
  Future<Result<Restaurant>> updateRestaurant(Restaurant r) async {
    try {
      final response = await _client.supabaseClient.client
          .from('restaurants')
          .update({
        'name': r.name,
        'address': r.address,
        'lat': r.lat,
        'lng': r.lng,
        'visible': r.visible,
      }).eq('id', r.id).select().single();
      return Success(Restaurant.fromMap(response));
    } catch (e) {
      return Failure('Failed to update restaurant: ${e.toString()}');
    }
  }

  /// Hard delete
  Future<Result<void>> deleteRestaurant(String id) async {
    try {
      await _client.supabaseClient.client.from('restaurants').delete().eq('id', id);
      return const Success(null);
    } catch (e) {
      return Failure('Failed to delete restaurant: ${e.toString()}');
    }
  }

  /// Terminates partnership: set visible=false and remove mappings
  Future<Result<void>> terminateRestaurant(String id) async {
    try {
      final supa = _client.supabaseClient.client;
      await supa.from('restaurants').update({'visible': false}).eq('id', id);
      // Best-effort: remove admin mappings if table exists
      try {
        await supa.from('restaurant_admins').delete().eq('restaurant_id', id);
      } catch (_) {}
      return const Success(null);
    } catch (e) {
      return Failure('Failed to terminate restaurant: ${e.toString()}');
    }
  }
}
