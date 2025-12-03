import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cleardish/data/sources/loyalty_api.dart';
import 'package:cleardish/data/sources/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import 'package:cleardish/core/utils/result.dart';
import 'package:cleardish/widgets/app_back_button.dart';

final _myBadgesProvider =
    FutureProvider.autoDispose<List<UserBadgeRow>>((ref) async {
  final uid = supa.Supabase.instance.client.auth.currentUser?.id;
  if (uid == null) return const [];
  final api = LoyaltyApi(SupabaseClient.instance);
  final res = await api.getUserBadges(uid);
  if (res is Failure) return const [];
  return (res as Success).data;
});

class MyBadgesScreen extends ConsumerWidget {
  const MyBadgesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_myBadgesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Badges & Rewards'),
        leading: const AppBackButton(fallbackRoute: '/home/profile'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed: $e')),
        data: (rows) {
          if (rows.isEmpty) {
            return const Center(child: Text('No badges yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemCount: rows.length,
            itemBuilder: (_, i) {
              final b = rows[i];
              return ListTile(
                leading: const Icon(Icons.verified, color: Colors.green),
                title: Text('${b.restaurantName} • ${b.type}'),
                subtitle: Text(
                    'Awarded: ${b.awardedAt.toLocal().toString().split(".").first}'
                    '${b.expiresAt != null ? ' • Expires: ${b.expiresAt!.toLocal().toString().split(".").first}' : ''}'),
              );
            },
          );
        },
      ),
    );
  }
}
