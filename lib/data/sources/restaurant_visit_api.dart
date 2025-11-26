import 'package:cleardish/core/utils/result.dart';
import 'package:cleardish/data/models/restaurant_visitor.dart';
import 'package:cleardish/data/sources/supabase_client.dart';

class RestaurantVisitApi {
  RestaurantVisitApi(this._client);
  final SupabaseClient _client;

  Future<Result<void>> recordVisit({
    required String restaurantId,
    required String userId,
  }) async {
    try {
      await _client.supabaseClient.client.from('restaurant_visits').insert({
        'restaurant_id': restaurantId,
        'user_id': userId,
      });
      return const Success(null);
    } catch (e) {
      return Failure('Failed to record visit: $e');
    }
  }

  Future<Result<List<RestaurantVisitor>>> getRecentVisitors(
    String restaurantId, {
    int limit = 20,
  }) async {
    try {
      final rows = await _client.supabaseClient.client
          .from('restaurant_visits')
          .select(
              'id, restaurant_id, user_id, visited_at, user_profiles(full_name)')
          .eq('restaurant_id', restaurantId)
          .order('visited_at', ascending: false)
          .limit(limit);

      final data = (rows as List)
          .map((row) => RestaurantVisitor.fromMap(row as Map<String, dynamic>))
          .toList();

      return Success(data);
    } catch (e) {
      return Failure('Failed to load visitors: $e');
    }
  }
}
