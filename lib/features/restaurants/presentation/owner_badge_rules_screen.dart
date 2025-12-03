import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cleardish/data/sources/loyalty_api.dart';
import 'package:cleardish/data/sources/restaurant_settings_api.dart';
import 'package:cleardish/data/sources/supabase_client.dart';
import 'package:cleardish/core/utils/result.dart';
import 'package:cleardish/widgets/app_back_button.dart';

final _rulesProvider =
    FutureProvider.autoDispose<List<LoyaltyRule>>((ref) async {
  final settings = RestaurantSettingsApi(SupabaseClient.instance);
  final me = await settings.getMyRestaurant();
  if (me is Failure) throw Exception((me as Failure).message);
  final api = LoyaltyApi(SupabaseClient.instance);
  final res = await api.getRules((me as Success).data.id);
  if (res is Failure) throw Exception((res as Failure).message);
  return (res as Success).data;
});

class OwnerBadgeRulesScreen extends ConsumerWidget {
  const OwnerBadgeRulesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncRules = ref.watch(_rulesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Badge Rules'),
        leading: const AppBackButton(fallbackRoute: '/home/profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Rule',
            onPressed: () async {
              await _openRuleDialog(context);
              ref.invalidate(_rulesProvider);
            },
          ),
        ],
      ),
      body: asyncRules.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed: $e')),
        data: (rules) {
          if (rules.isEmpty) {
            return const Center(child: Text('No rules yet. Add one with +'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: rules.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final r = rules[i];
              return ListTile(
                title: Text('Visits ${r.threshold} in ${r.windowDays} days'),
                subtitle: Text(
                    'Reward: ${r.rewardType} ${r.rewardValue}${r.rewardType == 'percent_off' ? '%' : ''} • ${r.active ? 'Active' : 'Disabled'}'),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) async {
                    final settings =
                        RestaurantSettingsApi(SupabaseClient.instance);
                    final me = await settings.getMyRestaurant();
                    if (me is Failure) return;
                    final api = LoyaltyApi(SupabaseClient.instance);
                    if (v == 'delete') {
                      await api.deleteRule(r.id);
                    } else if (v == 'toggle') {
                      await api.upsertRule(
                        id: r.id,
                        restaurantId: (me as Success).data.id,
                        threshold: r.threshold,
                        windowDays: r.windowDays,
                        rewardType: r.rewardType,
                        rewardValue: r.rewardValue,
                        active: !r.active,
                      );
                    }
                    ref.invalidate(_rulesProvider);
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'toggle', child: Text('Enable/Disable')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openRuleDialog(BuildContext context) async {
    final thresholdCtrl = TextEditingController(text: '5');
    final windowCtrl = TextEditingController(text: '30');
    final rewardCtrl = TextEditingController(text: '10');
    String rewardType = 'percent_off';
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Badge Rule'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: thresholdCtrl,
              decoration: const InputDecoration(labelText: 'Visits threshold'),
              keyboardType: const TextInputType.numberWithOptions(),
            ),
            TextField(
              controller: windowCtrl,
              decoration: const InputDecoration(labelText: 'Window (days)'),
              keyboardType: const TextInputType.numberWithOptions(),
            ),
            DropdownButtonFormField<String>(
              value: rewardType,
              items: const [
                DropdownMenuItem(value: 'percent_off', child: Text('% off')),
                DropdownMenuItem(value: 'free_item', child: Text('Free item')),
              ],
              onChanged: (v) => rewardType = v ?? 'percent_off',
              decoration: const InputDecoration(labelText: 'Reward type'),
            ),
            TextField(
              controller: rewardCtrl,
              decoration: const InputDecoration(labelText: 'Reward value'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );
    if (saved == true) {
      final settings = RestaurantSettingsApi(SupabaseClient.instance);
      final me = await settings.getMyRestaurant();
      if (me is Failure) return;
      final api = LoyaltyApi(SupabaseClient.instance);
      await api.upsertRule(
        restaurantId: (me as Success).data.id,
        threshold: int.tryParse(thresholdCtrl.text.trim()) ?? 5,
        windowDays: int.tryParse(windowCtrl.text.trim()) ?? 30,
        rewardType: rewardType,
        rewardValue: double.tryParse(rewardCtrl.text.trim()) ?? 10,
      );
    }
  }
}
