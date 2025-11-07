import 'package:equatable/equatable.dart';

/// Menu item model
///
/// Represents a menu item with allergens information.
class MenuItem extends Equatable {
  const MenuItem({
    required this.id,
    required this.restaurantId,
    required this.name,
    this.categoryId,
    this.description,
    this.price,
    this.allergens = const [],
    this.diets = const [],
  });

  final String id;
  final String restaurantId;
  final String name;
  final String? categoryId;
  final String? description;
  final double? price;
  final List<String> allergens;
  final List<String> diets;

  /// Creates MenuItem from Supabase map
  factory MenuItem.fromMap(Map<String, dynamic> map) {
    return MenuItem(
      id: map['id'] as String,
      restaurantId: map['restaurant_id'] as String,
      name: map['name'] as String,
      categoryId: map['category_id'] as String?,
      description: map['description'] as String?,
      price: map['price'] != null
          ? (map['price'] as num).toDouble()
          : null,
      allergens: List<String>.from(
        (map['allergens'] as List<dynamic>?) ?? [],
      ),
      diets: List<String>.from(
        (map['diets'] as List<dynamic>?) ?? [],
      ),
    );
  }

  /// Converts MenuItem to Supabase map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'restaurant_id': restaurantId,
      'name': name,
      'category_id': categoryId,
      'description': description,
      'price': price,
      'allergens': allergens,
      'diets': diets,
    };
  }

  /// Checks if this item contains any of the given allergens
  ///
  /// Returns true if there's an intersection between this item's allergens
  /// and the provided allergens list.
  bool containsAllergens(List<String> userAllergens) {
    if (userAllergens.isEmpty || allergens.isEmpty) {
      return false;
    }
    return allergens.any((allergen) => userAllergens.contains(allergen));
  }

  /// Returns true if this item satisfies ALL of the user's dietary preferences
  bool satisfiesDiets(List<String> userDiets) {
    if (userDiets.isEmpty) return true;
    if (diets.isEmpty) return false;
    for (final d in userDiets) {
      if (!diets.contains(d)) return false;
    }
    return true;
  }

  @override
  List<Object?> get props => [
        id,
        restaurantId,
        name,
        categoryId,
        description,
        price,
        allergens,
        diets,
      ];
}
