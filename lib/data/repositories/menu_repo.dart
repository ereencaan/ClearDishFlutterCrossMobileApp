import 'package:cleardish/core/utils/result.dart';
import 'package:cleardish/data/models/menu_item.dart';
import 'package:cleardish/data/sources/menu_api.dart';
import 'package:cleardish/data/sources/supabase_client.dart';

/// Menu repository
/// 
/// Provides menu data operations.
class MenuRepo {
  MenuRepo() : _api = MenuApi(SupabaseClient.instance);

  final MenuApi _api;

  /// Gets menu for a restaurant (grouped by category)
  Future<Result<Map<String, List<MenuItem>>>> getMenuByRestaurant(
    String restaurantId,
  ) async {
    return _api.getMenuByRestaurant(restaurantId);
  }
}

