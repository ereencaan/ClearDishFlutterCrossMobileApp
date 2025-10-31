import 'package:flutter_test/flutter_test.dart';
import 'package:cleardish/features/restaurants/controllers/restaurants_controller.dart';
import 'package:cleardish/data/models/restaurant.dart';

void main() {
  group('Restaurants Empty State Tests', () {
    test('RestaurantsState filteredRestaurants returns empty list when restaurants is empty', () {
      const state = RestaurantsState(
        restaurants: [],
        searchQuery: '',
      );

      expect(state.filteredRestaurants, isEmpty);
    });

    test('RestaurantsState filteredRestaurants returns empty when search has no matches', () {
      const state = RestaurantsState(
        restaurants: [
          Restaurant(
            id: '1',
            name: 'Test Restaurant',
            address: '123 Main St',
          ),
        ],
        searchQuery: 'NonExistent',
      );

      expect(state.filteredRestaurants, isEmpty);
    });

    test('RestaurantsState filteredRestaurants filters by name', () {
      const state = RestaurantsState(
        restaurants: [
          Restaurant(id: '1', name: 'Green Garden', address: '123 Main St'),
          Restaurant(id: '2', name: 'Ocean Breeze', address: '456 Harbor Ave'),
        ],
        searchQuery: 'Green',
      );

      expect(state.filteredRestaurants.length, equals(1));
      expect(state.filteredRestaurants.first.name, equals('Green Garden'));
    });
  });
}

