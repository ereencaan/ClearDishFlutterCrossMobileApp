import 'package:cleardish/core/utils/result.dart';
import 'package:cleardish/data/sources/supabase_client.dart';

class UserSubscriptionInfo {
  UserSubscriptionInfo({
    required this.active,
    this.plan,
    this.paidUntil,
  });

  final bool active;
  final String? plan; // monthly | yearly
  final DateTime? paidUntil;
}

class UserSubscriptionApi {
  UserSubscriptionApi(this._client);
  final SupabaseClient _client;

  Future<Result<UserSubscriptionInfo>> getMySubscription() async {
    try {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) return const Failure('Not authenticated');

      final row = await _client.supabaseClient.client
          .from('user_profiles')
          .select('user_sub_plan,user_sub_paid_until')
          .eq('user_id', uid)
          .maybeSingle();

      final plan = (row?['user_sub_plan'] as String?)?.trim();
      final rawUntil = row?['user_sub_paid_until'];

      DateTime? paidUntil;
      if (rawUntil is String) paidUntil = DateTime.tryParse(rawUntil);

      final now = DateTime.now();
      final active = paidUntil != null ? paidUntil.isAfter(now) : false;

      return Success(
        UserSubscriptionInfo(
          active: active,
          plan: plan,
          paidUntil: paidUntil,
        ),
      );
    } catch (e) {
      return Failure('Failed to load subscription: ${e.toString()}');
    }
  }
}

