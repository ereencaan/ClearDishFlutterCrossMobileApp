import 'package:equatable/equatable.dart';

/// Allergen model
/// 
/// Represents an allergen with display information.
/// This is a reference model for available allergens.
class Allergen extends Equatable {
  const Allergen({
    required this.id,
    required this.name,
    this.icon,
  });

  final String id;
  final String name;
  final String? icon;

  /// Standard allergen list
  static const List<Allergen> standardAllergens = [
    Allergen(id: 'gluten', name: 'Gluten'),
    Allergen(id: 'peanut', name: 'Peanut'),
    Allergen(id: 'tree_nut', name: 'Tree Nuts'),
    Allergen(id: 'milk', name: 'Milk'),
    Allergen(id: 'egg', name: 'Egg'),
    Allergen(id: 'fish', name: 'Fish'),
    Allergen(id: 'shellfish', name: 'Shellfish'),
    Allergen(id: 'soy', name: 'Soy'),
    Allergen(id: 'sesame', name: 'Sesame'),
  ];

  /// Standard diet list
  static const List<Allergen> standardDiets = [
    Allergen(id: 'vegan', name: 'Vegan'),
    Allergen(id: 'vegetarian', name: 'Vegetarian'),
    Allergen(id: 'keto', name: 'Keto'),
    Allergen(id: 'halal', name: 'Halal'),
    Allergen(id: 'kosher', name: 'Kosher'),
    Allergen(id: 'paleo', name: 'Paleo'),
  ];

  @override
  List<Object?> get props => [id, name, icon];
}


