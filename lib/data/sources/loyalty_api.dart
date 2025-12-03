import 'package:cleardish/core/utils/result.dart';
import 'package:cleardish/data/sources/supabase_client.dart';

class LoyaltyRule {
  const LoyaltyRule({
    required this.id,
    required this.restaurantId,
    required this.type, // visits
    required this.threshold,
    required this.windowDays,
    required this.rewardType, // percent_off | free_item
    required this.rewardValue,
    required this.active,
  });
  final String id;
  final String restaurantId;
  final String type;
  final int threshold;
  final int windowDays;
  final String rewardType;
  final double rewardValue;
  final bool active;

  factory LoyaltyRule.fromMap(Map<String, dynamic> m) => LoyaltyRule(
        id: m['id'] as String,
        restaurantId: m['restaurant_id'] as String,
        type: m['type'] as String,
        threshold: (m['threshold'] as num).toInt(),
        windowDays: (m['window_days'] as num).toInt(),
        rewardType: m['reward_type'] as String,
        rewardValue: (m['reward_value'] as num).toDouble(),
        active: (m['active'] as bool?) ?? true,
      );
}

class UserBadgeRow {
  const UserBadgeRow({
    required this.id,
    required this.restaurantName,
    required this.type,
    required this.awardedAt,
    required this.expiresAt,
  });
  final String id;
  final String restaurantName;
  final String type;
  final DateTime awardedAt;
  final DateTime? expiresAt;
}

class LoyaltyApi {
  LoyaltyApi(this._client);
  final SupabaseClient _client;

  Future<Result<List<LoyaltyRule>>> getRules(String restaurantId) async {
    try {
      final rows = await _client.supabaseClient.client
          .from('badge_rules')
          .select()
          .eq('restaurant_id', restaurantId)
          .order('created_at', ascending: false);
      final list = (rows as List)
          .map((e) => LoyaltyRule.fromMap(e as Map<String, dynamic>))
          .toList();
      return Success(list);
    } catch (e) {
      return Failure('Failed to load rules: $e');
    }
  }

  Future<Result<void>> upsertRule({
    String? id,
    required String restaurantId,
    required int threshold,
    required int windowDays,
    required String rewardType,
    required double rewardValue,
    bool active = true,
  }) async {
    try {
      final data = {
        if (id != null) 'id': id,
        'restaurant_id': restaurantId,
        'type': 'visits',
        'threshold': threshold,
        'window_days': windowDays,
        'reward_type': rewardType,
        'reward_value': rewardValue,
        'active': active,
      };
      await _client.supabaseClient.client.from('badge_rules').upsert(data);
      return const Success(null);
    } catch (e) {
      return Failure('Failed to save rule: $e');
    }
  }

  Future<Result<void>> deleteRule(String id) async {
    try {
      await _client.supabaseClient.client
          .from('badge_rules')
          .delete()
          .eq('id', id);
      return const Success(null);
    } catch (e) {
      return Failure('Failed to delete rule: $e');
    }
  }

  Future<Result<List<UserBadgeRow>>> getUserBadges(String userId) async {
    try {
      final rows = await _client.supabaseClient.client
          .from('user_badges')
          .select('id,type,awarded_at,expires_at,restaurants(name)')
          .eq('user_id', userId)
          .order('awarded_at', ascending: false);
      final list = (rows as List).map((e) {
        final m = e as Map<String, dynamic>;
        return UserBadgeRow(
          id: m['id'] as String,
          restaurantName: (m['restaurants']?['name'] as String?) ?? 'Restaurant',
          type: m['type'] as String,
          awardedAt: DateTime.parse(m['awarded_at'] as String),
          expiresAt: (m['expires_at'] as String?) != null
              ? DateTime.parse(m['expires_at'] as String)
              : null,
        );
      }).toList();
      return Success(list);
    } catch (e) {
      return Failure('Failed to load badges: $e');
    }
  }
}
