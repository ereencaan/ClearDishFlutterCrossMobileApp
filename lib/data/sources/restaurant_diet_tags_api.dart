import 'package:cleardish/core/utils/result.dart';
import 'package:cleardish/data/sources/supabase_client.dart';

class RestaurantDietTagsApi {
  RestaurantDietTagsApi(this._client);
  final SupabaseClient _client;

  Future<Result<List<String>>> listTags({required String restaurantId}) async {
    try {
      final rows = await _client.supabaseClient.client
          .from('restaurant_diet_tags')
          .select('tag')
          .eq('restaurant_id', restaurantId)
          .order('tag', ascending: true);
      final tags = (rows as List)
          .map((r) => (r as Map<String, dynamic>)['tag'] as String)
          .where((t) => t.trim().isNotEmpty)
          .toList(growable: false);
      return Success(tags);
    } catch (e) {
      return Failure('Failed to load tags: ${e.toString()}');
    }
  }

  Future<Result<void>> replaceTags({
    required String restaurantId,
    required List<String> tags,
  }) async {
    try {
      final normalized = tags
          .map((t) => t.trim().toLowerCase())
          .where((t) => t.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

      // Delete removed
      await _client.supabaseClient.client
          .from('restaurant_diet_tags')
          .delete()
          .eq('restaurant_id', restaurantId);

      if (normalized.isNotEmpty) {
        await _client.supabaseClient.client.from('restaurant_diet_tags').insert(
          normalized
              .map((t) => {'restaurant_id': restaurantId, 'tag': t})
              .toList(),
        );
      }
      return const Success(null);
    } catch (e) {
      return Failure('Failed to save tags: ${e.toString()}');
    }
  }
}

