import 'package:cleardish/core/utils/result.dart';
import 'package:cleardish/data/models/menu_category.dart';
import 'package:cleardish/data/models/menu_item.dart';
import 'package:cleardish/data/sources/supabase_client.dart';

/// Menu API
///
/// Handles menu data operations with Supabase.
class MenuApi {
  MenuApi(this._client);
  final SupabaseClient _client;

  /// Gets menu categories for a restaurant
  Future<Result<List<MenuCategory>>> getCategories(String restaurantId) async {
    try {
      final response = await _client.supabaseClient.client.from('menu_categories').select().eq(
            'restaurant_id',
            restaurantId,
          ).order('sort_order');

      final categories = (response as List)
          .map((json) => MenuCategory.fromMap(json as Map<String, dynamic>))
          .toList();

      return Success(categories);
    } catch (e) {
      return Failure('Failed to fetch categories: ${e.toString()}');
    }
  }

  /// Gets menu items for a restaurant
  Future<Result<List<MenuItem>>> getMenuItems(String restaurantId) async {
    try {
      final response = await _client.supabaseClient.client.from('menu_items').select().eq(
            'restaurant_id',
            restaurantId,
          );

      final items = (response as List)
          .map((json) => MenuItem.fromMap(json as Map<String, dynamic>))
          .toList();

      return Success(items);
    } catch (e) {
      return Failure('Failed to fetch menu items: ${e.toString()}');
    }
  }

  /// Gets menu items grouped by category
  Future<Result<Map<String, List<MenuItem>>>> getMenuByRestaurant(
    String restaurantId,
  ) async {
    try {
      final categoriesResult = await getCategories(restaurantId);
      if (categoriesResult.isFailure) {
        return Failure(categoriesResult.errorOrNull!);
      }

      final itemsResult = await getMenuItems(restaurantId);
      if (itemsResult.isFailure) {
        return Failure(itemsResult.errorOrNull!);
      }

      final categories = categoriesResult.dataOrNull!;
      final items = itemsResult.dataOrNull!;

      // Group items by category
      final Map<String, List<MenuItem>> menuMap = {};
      for (final category in categories) {
        menuMap[category.id] = items
            .where((item) => item.categoryId == category.id)
            .toList();
      }

      // Items without category
      final uncategorizedItems = items.where((item) => item.categoryId == null);
      if (uncategorizedItems.isNotEmpty) {
        menuMap['uncategorized'] = uncategorizedItems.toList();
      }

      return Success(menuMap);
    } catch (e) {
      return Failure('Failed to fetch menu: ${e.toString()}');
    }
  }
}
