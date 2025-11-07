import 'package:flutter_test/flutter_test.dart';
import 'package:cleardish/data/models/menu_item.dart';

void main() {
  group('Allergen Filter Tests', () {
    test('MenuItem.containsAllergens returns true when intersection exists',
        () {
      const item = MenuItem(
        id: '1',
        restaurantId: 'rest1',
        name: 'Pasta with Gluten',
        allergens: ['gluten', 'milk'],
      );

      expect(item.containsAllergens(['gluten']), isTrue);
      expect(item.containsAllergens(['milk']), isTrue);
      expect(item.containsAllergens(['gluten', 'peanut']), isTrue);
    });

    test('MenuItem.containsAllergens returns false when no intersection', () {
      const item = MenuItem(
        id: '1',
        restaurantId: 'rest1',
        name: 'Safe Item',
        allergens: ['gluten', 'milk'],
      );

      expect(item.containsAllergens(['peanut']), isFalse);
      expect(item.containsAllergens(['soy']), isFalse);
      expect(item.containsAllergens([]), isFalse);
    });

    test('MenuItem.containsAllergens returns false when item has no allergens',
        () {
      const item = MenuItem(
        id: '1',
        restaurantId: 'rest1',
        name: 'Allergen-Free Item',
        allergens: [],
      );

      expect(item.containsAllergens(['gluten']), isFalse);
      expect(item.containsAllergens(['peanut', 'milk']), isFalse);
    });
  });
}
