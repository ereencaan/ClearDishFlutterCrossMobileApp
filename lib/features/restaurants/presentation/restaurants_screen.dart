import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cleardish/features/restaurants/controllers/restaurants_controller.dart';
import 'package:cleardish/features/restaurants/widgets/restaurant_card.dart';

/// Restaurants list screen
/// 
/// Displays a list of available restaurants with search functionality.
class RestaurantsScreen extends ConsumerStatefulWidget {
  const RestaurantsScreen({super.key});

  @override
  ConsumerState<RestaurantsScreen> createState() => _RestaurantsScreenState();
}

class _RestaurantsScreenState extends ConsumerState<RestaurantsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(restaurantsControllerProvider);

    // Update search query when text changes
    _searchController.addListener(() {
      ref.read(restaurantsControllerProvider.notifier).updateSearchQuery(
            _searchController.text,
          );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurants'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search restaurants...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
              ),
            ),
          ),
          Expanded(
            child: _buildBody(state),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(RestaurantsState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error: ${state.error}',
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(restaurantsControllerProvider.notifier).loadRestaurants();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.filteredRestaurants.isEmpty) {
      return const Center(
        child: Text('No restaurants found'),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.read(restaurantsControllerProvider.notifier).loadRestaurants();
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: state.filteredRestaurants.length,
        itemBuilder: (context, index) {
          final restaurant = state.filteredRestaurants[index];
          return RestaurantCard(
            restaurant: restaurant,
            onTap: () {
              context.go('/home/restaurants/${restaurant.id}');
            },
          );
        },
      ),
    );
  }
}


