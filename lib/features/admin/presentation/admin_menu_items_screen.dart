import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cleardish/data/sources/supabase_client.dart';
import 'package:cleardish/widgets/app_back_button.dart';

final _menuItemsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final rows = await SupabaseClient.instance.supabaseClient.client
      .from('menu_items')
      .select('id,name,price,restaurant_id,restaurants(name)')
      .order('name');
  return (rows as List).cast<Map<String, dynamic>>();
});

class AdminMenuItemsScreen extends ConsumerStatefulWidget {
  const AdminMenuItemsScreen({super.key});
  @override
  ConsumerState<AdminMenuItemsScreen> createState() =>
      _AdminMenuItemsScreenState();
}

class _AdminMenuItemsScreenState
    extends ConsumerState<AdminMenuItemsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final asyncItems = ref.watch(_menuItemsProvider);
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallbackRoute: '/admin'),
        title: const Text('Menu Items'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search items or restaurants...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: asyncItems.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Failed: $e')),
              data: (rows) {
                final filtered = rows.where((m) {
                  if (_query.isEmpty) return true;
                  final name = (m['name'] as String? ?? '').toLowerCase();
                  final restName =
                      (m['restaurants']?['name'] as String? ?? '')
                          .toLowerCase();
                  return name.contains(_query) || restName.contains(_query);
                }).toList();
                if (filtered.isEmpty) {
                  return const Center(child: Text('No items'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final row = filtered[i];
                    final restName = row['restaurants']?['name'] as String?;
                    final price = row['price'] as num?;
                    return ListTile(
                      title: Text(row['name'] as String? ?? 'Unnamed'),
                      subtitle: Text(restName ?? '—'),
                      trailing: price != null
                          ? Text('£${price.toStringAsFixed(2)}')
                          : null,
                      onTap: () {
                        final rid = row['restaurant_id'] as String?;
                        if (rid != null) {
                          context.go('/home/menu/$rid');
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
