import 'package:cleardish/core/utils/result.dart';
import 'package:cleardish/data/models/restaurant_location.dart';
import 'package:cleardish/data/sources/supabase_client.dart';

class RestaurantLocationsApi {
  RestaurantLocationsApi(this._client);
  final SupabaseClient _client;

  Future<Result<List<RestaurantLocation>>> listLocations({
    required String restaurantId,
  }) async {
    try {
      final rows = await _client.supabaseClient.client
          .from('restaurant_locations')
          .select()
          .eq('restaurant_id', restaurantId)
          .order('is_primary', ascending: false)
          .order('created_at', ascending: true);
      final list = (rows as List)
          .map((r) => RestaurantLocation.fromMap(r as Map<String, dynamic>))
          .toList(growable: false);
      return Success(list);
    } catch (e) {
      return Failure('Failed to load locations: ${e.toString()}');
    }
  }

  Future<Result<void>> createLocation(RestaurantLocation location) async {
    try {
      await _client.supabaseClient.client
          .from('restaurant_locations')
          .insert(location.toInsertMap());
      return const Success(null);
    } catch (e) {
      return Failure('Failed to create location: ${e.toString()}');
    }
  }

  Future<Result<void>> updateLocation(RestaurantLocation location) async {
    try {
      await _client.supabaseClient.client
          .from('restaurant_locations')
          .update(location.toUpdateMap())
          .eq('id', location.id);
      return const Success(null);
    } catch (e) {
      return Failure('Failed to update location: ${e.toString()}');
    }
  }

  Future<Result<void>> deleteLocation(String id) async {
    try {
      await _client.supabaseClient.client.from('restaurant_locations').delete().eq('id', id);
      return const Success(null);
    } catch (e) {
      return Failure('Failed to delete location: ${e.toString()}');
    }
  }
}

