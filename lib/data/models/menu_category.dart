import 'package:equatable/equatable.dart';

/// Menu category model
/// 
/// Represents a category within a restaurant's menu.
class MenuCategory extends Equatable {
  const MenuCategory({
    required this.id,
    required this.restaurantId,
    required this.name,
    this.sortOrder = 0,
  });

  final String id;
  final String restaurantId;
  final String name;
  final int sortOrder;

  /// Creates MenuCategory from Supabase map
  factory MenuCategory.fromMap(Map<String, dynamic> map) {
    return MenuCategory(
      id: map['id'] as String,
      restaurantId: map['restaurant_id'] as String,
      name: map['name'] as String,
      sortOrder: (map['sort_order'] as int?) ?? 0,
    );
  }

  /// Converts MenuCategory to Supabase map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'restaurant_id': restaurantId,
      'name': name,
      'sort_order': sortOrder,
    };
  }

  @override
  List<Object?> get props => [id, restaurantId, name, sortOrder];
}

