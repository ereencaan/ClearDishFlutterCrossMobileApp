import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import 'package:cleardish/features/menu/controllers/menu_controller.dart';
import 'package:cleardish/features/profile/controllers/profile_controller.dart';
import 'package:cleardish/features/menu/widgets/menu_item_tile.dart';
import 'package:cleardish/data/models/menu_item.dart';
import 'package:cleardish/data/sources/restaurant_visit_api.dart';
import 'package:cleardish/data/sources/supabase_client.dart';
import 'package:cleardish/widgets/app_back_button.dart';

/// Menu screen
///
/// Displays menu items with safe-only filter option.
class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({
    required this.restaurantId,
    super.key,
  });

  final String restaurantId;

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  @override
  void initState() {
    super.initState();
    // Load profile to get user allergens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = supa.Supabase.instance.client.auth.currentUser;
      if (user != null) {
        ref.read(profileControllerProvider.notifier).loadProfile(user.id);
        final role = user.userMetadata?['role'] as String?;
        if (role != 'restaurant') {
          unawaited(
            RestaurantVisitApi(SupabaseClient.instance).recordVisit(
              restaurantId: widget.restaurantId,
              userId: user.id,
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final menuState = ref.watch(
      menuControllerProvider(widget.restaurantId),
    );
    final profileState = ref.watch(profileControllerProvider);

    final userAllergens = profileState.profile?.allergens ?? [];
    final userDiets = profileState.profile?.diets ?? [];
    final filteredItems = ref
        .read(menuControllerProvider(widget.restaurantId).notifier)
        .getFilteredItems(userAllergens, userDiets);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
        leading: const AppBackButton(
          fallbackRoute: '/home/restaurants',
        ),
        actions: [
          Switch(
            value: menuState.safeOnly,
            onChanged: (value) {
              ref
                  .read(menuControllerProvider(widget.restaurantId).notifier)
                  .toggleSafeOnly();
            },
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: Text('Safe Only'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (menuState.safeOnly && menuState.hiddenCount > 0)
            Builder(builder: (context) {
              final colors = Theme.of(context).colorScheme;
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${menuState.hiddenCount} item(s) hidden (allergen/diet)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.onSecondaryContainer,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }),
          Expanded(
            child: _buildBody(menuState, filteredItems),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(MenuState state, List<MenuItem> filteredItems) {
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
                ref
                    .read(menuControllerProvider(widget.restaurantId).notifier)
                    .loadMenu();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (filteredItems.isEmpty) {
      return const Center(
        child: Text('No menu items available'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final item = filteredItems[index];
        return MenuItemTile(item: item);
      },
    );
  }
}
