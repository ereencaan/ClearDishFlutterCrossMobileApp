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

  /// Standard allergen list (EU 14 Allergens)
  static const List<Allergen> standardAllergens = [
    Allergen(id: 'molluscs', name: 'Molluscs'),
    Allergen(id: 'eggs', name: 'Eggs'),
    Allergen(id: 'fish', name: 'Fish'),
    Allergen(id: 'lupin', name: 'Lupin'),
    Allergen(id: 'soya', name: 'Soya'),
    Allergen(id: 'milk', name: 'Milk'),
    Allergen(id: 'peanuts', name: 'Peanuts'),
    Allergen(id: 'gluten', name: 'Gluten'),
    Allergen(id: 'crustaceans', name: 'Crustaceans'),
    Allergen(id: 'mustard', name: 'Mustard'),
    Allergen(id: 'nuts', name: 'Nuts'),
    Allergen(id: 'sesame', name: 'Sesame'),
    Allergen(id: 'celery', name: 'Celery'),
    Allergen(id: 'sulphites', name: 'Sulphites'),
  ];

  /// Standard diet list
  static const List<Allergen> standardDiets = [
    Allergen(id: 'vegan', name: 'Vegan'),
    Allergen(id: 'vegetarian', name: 'Vegetarian'),
    Allergen(id: 'halal', name: 'Halal'),
    Allergen(id: 'kosher', name: 'Kosher'),
    Allergen(id: 'sugar_free', name: 'Sugar Free'),
    Allergen(id: 'dairy_free', name: 'Dairy Free'),
    Allergen(id: 'gluten_free', name: 'Gluten Free'),
  ];

  @override
  List<Object?> get props => [id, name, icon];
}
