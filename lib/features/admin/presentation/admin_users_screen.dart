import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cleardish/data/sources/supabase_client.dart';
import 'package:cleardish/data/models/user_profile.dart';

final adminUsersProvider = FutureProvider.autoDispose<List<UserProfile>>((ref) async {
  final rows = await SupabaseClient.instance.supabaseClient.client
      .from('user_profiles')
      .select()
      .order('full_name', ascending: true);
  return (rows as List)
      .map((e) => UserProfile.fromMap(e as Map<String, dynamic>))
      .toList();
});

class AdminUsersScreen extends ConsumerWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(adminUsersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('All Users')),
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load users: $e')),
        data: (users) {
          if (users.isEmpty) return const Center(child: Text('No users'));
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: users.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final u = users[i];
              return ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(u.fullName ?? u.userId),
                subtitle: Text([
                  if ((u.allergens).isNotEmpty) 'Allergens: ${u.allergens.join(', ')}',
                  if ((u.diets).isNotEmpty) 'Diets: ${u.diets.join(', ')}',
                ].join('  •  ')),
              );
            },
          );
        },
      ),
    );
  }
}
