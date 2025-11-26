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
      final response = await _client.supabaseClient.client
          .from('menu_categories')
          .select()
          .eq(
            'restaurant_id',
            restaurantId,
          )
          .order('sort_order');

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
      final response =
          await _client.supabaseClient.client.from('menu_items').select().eq(
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
        menuMap[category.id] =
            items.where((item) => item.categoryId == category.id).toList();
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

  // ---------- CRUD: Categories ----------
  Future<Result<MenuCategory>> addCategory({
    required String restaurantId,
    required String name,
    int sortOrder = 0,
  }) async {
    try {
      final inserted = await _client.supabaseClient.client
          .from('menu_categories')
          .insert({
            'restaurant_id': restaurantId,
            'name': name,
            'sort_order': sortOrder,
          })
          .select()
          .single();
      return Success(MenuCategory.fromMap(inserted as Map<String, dynamic>));
    } catch (e) {
      return Failure('Failed to add category: ${e.toString()}');
    }
  }

  Future<Result<void>> updateCategory({
    required String id,
    required String name,
    int? sortOrder,
  }) async {
    try {
      final data = {
        'name': name,
        if (sortOrder != null) 'sort_order': sortOrder,
      };
      await _client.supabaseClient.client
          .from('menu_categories')
          .update(data)
          .eq('id', id);
      return const Success(null);
    } catch (e) {
      return Failure('Failed to update category: ${e.toString()}');
    }
  }

  Future<Result<void>> deleteCategory(String id) async {
    try {
      await _client.supabaseClient.client
          .from('menu_categories')
          .delete()
          .eq('id', id);
    } catch (e) {
      return Failure('Failed to delete category: ${e.toString()}');
    }
    return const Success(null);
  }

  // ---------- CRUD: Items ----------
  Future<Result<MenuItem>> addItem({
    required String restaurantId,
    String? categoryId,
    required String name,
    String? description,
    double? price,
    List<String>? allergens,
    List<String>? diets,
  }) async {
    try {
      final inserted = await _client.supabaseClient.client
          .from('menu_items')
          .insert({
            'restaurant_id': restaurantId,
            'category_id': categoryId,
            'name': name,
            'description': description,
            'price': price,
            'allergens': allergens ?? <String>[],
            'diets': diets ?? <String>[],
          })
          .select()
          .single();
      return Success(MenuItem.fromMap(inserted as Map<String, dynamic>));
    } catch (e) {
      return Failure('Failed to add item: ${e.toString()}');
    }
  }

  Future<Result<void>> updateItem({
    required String id,
    String? categoryId,
    String? name,
    String? description,
    double? price,
    List<String>? allergens,
    List<String>? diets,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (categoryId != null) data['category_id'] = categoryId;
      if (name != null) data['name'] = name;
      if (description != null) data['description'] = description;
      if (price != null) data['price'] = price;
      if (allergens != null) data['allergens'] = allergens;
      if (diets != null) data['diets'] = diets;
      await _client.supabaseClient.client
          .from('menu_items')
          .update(data)
          .eq('id', id);
      return const Success(null);
    } catch (e) {
      return Failure('Failed to update item: ${e.toString()}');
    }
  }

  Future<Result<void>> deleteItem(String id) async {
    try {
      await _client.supabaseClient.client
          .from('menu_items')
          .delete()
          .eq('id', id);
      return const Success(null);
    } catch (e) {
      return Failure('Failed to delete item: ${e.toString()}');
    }
  }
}
