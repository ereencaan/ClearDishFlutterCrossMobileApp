import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cleardish/data/repositories/restaurant_repo.dart';
import 'package:cleardish/data/models/restaurant.dart';
import 'package:cleardish/core/utils/result.dart';

/// Restaurant detail screen
/// 
/// Shows restaurant details and navigation to menu.
class RestaurantDetailScreen extends ConsumerStatefulWidget {
  const RestaurantDetailScreen({
    required this.restaurantId,
    super.key,
  });

  final String restaurantId;

  @override
  ConsumerState<RestaurantDetailScreen> createState() =>
      _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState
    extends ConsumerState<RestaurantDetailScreen> {
  Restaurant? _restaurant;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRestaurant();
  }

  Future<void> _loadRestaurant() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final repo = RestaurantRepo();
    final result = await repo.getRestaurant(widget.restaurantId);

    setState(() {
      _isLoading = false;
      if (result.isFailure) {
        _error = result.errorOrNull;
      } else {
        _restaurant = result.dataOrNull;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant Details'),
      ),
      body: _buildBody(),
      floatingActionButton: _restaurant != null
          ? FloatingActionButton.extended(
              onPressed: () {
                context.go('/home/menu/${widget.restaurantId}');
              },
              label: const Text('View Menu'),
              icon: const Icon(Icons.restaurant_menu),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error: $_error',
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadRestaurant,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_restaurant == null) {
      return const Center(child: Text('Restaurant not found'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _restaurant!.name,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          if (_restaurant!.address != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.location_on),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _restaurant!.address!,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}


