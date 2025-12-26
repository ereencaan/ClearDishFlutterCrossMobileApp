import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cleardish/data/repositories/restaurant_repo.dart';
import 'package:cleardish/data/models/restaurant.dart';
import 'package:cleardish/data/models/user_profile.dart';
import 'package:cleardish/data/sources/supabase_client.dart';
import 'package:cleardish/core/utils/result.dart';
import 'package:cleardish/widgets/app_back_button.dart';

final _restaurantsFutureProvider =
    FutureProvider.autoDispose<List<Restaurant>>((ref) async {
  final repo = RestaurantRepo();
  final result = await repo.getRestaurants();
  if (result.isFailure) {
    throw Exception(result.errorOrNull);
  }
  return result.dataOrNull ?? const [];
});

final _usersFutureProvider =
    FutureProvider.autoDispose<List<UserProfile>>((ref) async {
  try {
    final rows = await SupabaseClient.instance.supabaseClient.client
        .from('user_profiles')
        .select()
        .limit(100);
    return (rows as List)
        .map((e) => UserProfile.fromMap(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    // Likely blocked by RLS; return empty list but keep UI functional
    return const <UserProfile>[];
  }
});

final _menuItemsCountProvider = FutureProvider.autoDispose<int>((ref) async {
  try {
    final rows = await SupabaseClient.instance.supabaseClient.client
        .from('menu_items')
        .select('id');
    return (rows as List).length;
  } catch (_) {
    // If blocked by RLS or any error, treat as 0 but keep UI working
    return 0;
  }
});

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurantsAsync = ref.watch(_restaurantsFutureProvider);
    final usersAsync = ref.watch(_usersFutureProvider);
    final menuItemsAsync = ref.watch(_menuItemsCountProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallbackRoute: '/welcome'),
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await SupabaseClient.instance.auth.signOut();
              if (context.mounted) context.go('/welcome');
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 900;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, Admin',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                // Overview cards
                _OverviewGrid(
                  isWide: isWide,
                  restaurantsAsync: restaurantsAsync,
                  usersAsync: usersAsync,
                  menuItemsAsync: menuItemsAsync,
                ),
                const SizedBox(height: 24),
                _QuickLinks(),
                const SizedBox(height: 24),
                // Lists
                const _SectionHeader(title: 'Restaurants'),
                const SizedBox(height: 8),
                _RestaurantsList(restaurantsAsync: restaurantsAsync),
                const SizedBox(height: 24),
                const _SectionHeader(title: 'Users'),
                const SizedBox(height: 8),
                _UsersList(usersAsync: usersAsync),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _OverviewGrid extends StatelessWidget {
  const _OverviewGrid({
    required this.isWide,
    required this.restaurantsAsync,
    required this.usersAsync,
    required this.menuItemsAsync,
  });

  final bool isWide;
  final AsyncValue<List<Restaurant>> restaurantsAsync;
  final AsyncValue<List<UserProfile>> usersAsync;
  final AsyncValue<int> menuItemsAsync;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final cards = <Widget>[
      _MetricCard(
        title: 'Restaurants',
        value: restaurantsAsync.when(
          data: (d) => d.length.toString(),
          loading: () => '—',
          error: (_, __) => '—',
        ),
        icon: Icons.storefront,
        color: color.primaryContainer,
      ),
      _MetricCard(
        title: 'Users',
        value: usersAsync.when(
          data: (d) => d.length.toString(),
          loading: () => '—',
          error: (_, __) => '—',
        ),
        icon: Icons.people,
        color: color.secondaryContainer,
      ),
      _MetricCard(
        title: 'Menu Items',
        value: menuItemsAsync.when(
          data: (c) => c.toString(),
          loading: () => '—',
          error: (_, __) => '—',
        ),
        icon: Icons.restaurant_menu,
        color: color.tertiaryContainer,
      ),
    ];

    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isWide ? 3 : 1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: isWide ? 3 : 2.6,
      ),
      children: cards,
    );
  }
}

class _QuickLinks extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        FilledButton.icon(
          onPressed: () => context.go('/admin/restaurants'),
          icon: const Icon(Icons.store_mall_directory),
          label: const Text('Manage Restaurants'),
        ),
        FilledButton.tonalIcon(
          onPressed: () => context.go('/home/nearby'),
          icon: const Icon(Icons.near_me),
          label: const Text('Nearby'),
        ),
        FilledButton.tonalIcon(
          onPressed: () => context.go('/admin/activity'),
          icon: const Icon(Icons.timeline),
          label: const Text('Activity'),
        ),
        FilledButton.tonalIcon(
          onPressed: () => context.go('/admin/users'),
          icon: const Icon(Icons.people_alt_outlined),
          label: const Text('All Users'),
        ),
        FilledButton.tonalIcon(
          onPressed: () => context.go('/admin/approvals'),
          icon: const Icon(Icons.verified),
          label: const Text('Pending Approvals'),
        ),
        FilledButton.tonalIcon(
          onPressed: () => context.go('/home/profile'),
          icon: const Icon(Icons.person),
          label: const Text('Profile'),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleLarge
          ?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}

class _RestaurantsList extends StatelessWidget {
  const _RestaurantsList({required this.restaurantsAsync});
  final AsyncValue<List<Restaurant>> restaurantsAsync;
  @override
  Widget build(BuildContext context) {
    return restaurantsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Failed to load restaurants: $e'),
      data: (restaurants) {
        if (restaurants.isEmpty) {
          return const Text('No restaurants');
        }
        return Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: restaurants.length.clamp(0, 10),
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final r = restaurants[i];
              return ListTile(
                title: Text(r.name),
                subtitle: Text(r.address ?? ''),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/home/restaurants/${r.id}'),
              );
            },
          ),
        );
      },
    );
  }
}

class _UsersList extends StatelessWidget {
  const _UsersList({required this.usersAsync});
  final AsyncValue<List<UserProfile>> usersAsync;
  @override
  Widget build(BuildContext context) {
    return usersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Failed to load users: $e'),
      data: (users) {
        if (users.isEmpty) {
          return const Text('No users or insufficient permissions');
        }
        return Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: users.length.clamp(0, 10),
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final u = users[i];
              return ListTile(
                title: Text(u.fullName ?? u.userId),
                subtitle: Text(u.address ?? ''),
              );
            },
          ),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withOpacity(0.35),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Icon(icon, size: 36),
          ],
        ),
      ),
    );
  }
}
