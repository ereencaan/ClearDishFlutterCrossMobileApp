import 'package:cleardish/core/utils/result.dart';
import 'package:cleardish/data/models/promotion.dart';
import 'package:cleardish/data/models/restaurant.dart';
import 'package:cleardish/data/sources/supabase_client.dart';

class RestaurantSettingsApi {
  RestaurantSettingsApi(this._client);
  final SupabaseClient _client;

  /// Returns the first restaurant mapped to current user via restaurant_admins
  Future<Result<Restaurant>> getMyRestaurant() async {
    try {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) return const Failure('Not authenticated');

      final mapping = await _client.supabaseClient.client
          .from('restaurant_admins')
          .select('restaurant_id')
          .eq('user_id', uid)
          .maybeSingle();

      if (mapping == null) {
        return const Failure('No restaurant assigned to this account');
      }

      final restaurantId = (mapping['restaurant_id'] as String);
      final r = await _client.supabaseClient.client
          .from('restaurants')
          .select()
          .eq('id', restaurantId)
          .single();
      return Success(Restaurant.fromMap(r));
    } catch (e) {
      return Failure('Failed to load restaurant: ${e.toString()}');
    }
  }

  /// Upserts address, contact and coordinates
  Future<Result<Restaurant>> saveAddress({
    required String restaurantId,
    required String address,
    String? phone,
    double? lat,
    double? lng,
  }) async {
    try {
      final data = <String, dynamic>{
        'address': address,
        if (phone != null) 'phone': phone,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      };
      // Use update instead of upsert to avoid INSERT path and RLS 'new row' checks
      await _client.supabaseClient.client
          .from('restaurants')
          .update(data)
          .eq('id', restaurantId);
      final r = await _client.supabaseClient.client
          .from('restaurants')
          .select()
          .eq('id', restaurantId)
          .single();
      return Success(Restaurant.fromMap(r));
    } catch (e) {
      return Failure('Failed to save address: ${e.toString()}');
    }
  }

  /// Creates a badge for current period
  Future<Result<void>> createBadge({
    required String restaurantId,
    required String type, // 'weekly' or 'monthly'
    required DateTime periodStart,
    required DateTime periodEnd,
  }) async {
    try {
      await _client.supabaseClient.client.from('restaurant_badges').insert({
        'restaurant_id': restaurantId,
        'type': type,
        'period_start': periodStart.toIso8601String(),
        'period_end': periodEnd.toIso8601String(),
      });
      return const Success(null);
    } catch (e) {
      return Failure('Failed to create badge: ${e.toString()}');
    }
  }

  /// Creates a promotion (global or targeted if userId provided)
  Future<Result<void>> createPromotion({
    required String restaurantId,
    required String title,
    String? description,
    required double percentOff,
    DateTime? startsAt,
    DateTime? endsAt,
    String? userId,
  }) async {
    try {
      final now = DateTime.now();
      final data = {
        'restaurant_id': restaurantId,
        'title': title,
        'description': description,
        'percent_off': percentOff,
        'starts_at': (startsAt ?? now).toIso8601String(),
        'ends_at':
            (endsAt ?? now.add(const Duration(days: 7))).toIso8601String(),
        'user_id': userId,
        'active': true,
      };
      await _client.supabaseClient.client.from('promotions').insert(data);
      return const Success(null);
    } catch (e) {
      return Failure('Failed to create promotion: ${e.toString()}');
    }
  }

  /// Creates a restaurant and maps current user as its admin/owner
  Future<Result<String>> createRestaurantWithOwner({
    required String name,
    required String address,
    String? phone,
  }) async {
    try {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) return const Failure('Not authenticated');

      final inserted = await _client.supabaseClient.client
          .from('restaurants')
          .insert({
            'name': name,
            'address': address,
            'phone': phone,
            'visible': true,
          })
          .select()
          .single();

      final restaurantId = inserted['id'] as String;

      await _client.supabaseClient.client.from('restaurant_admins').insert({
        'restaurant_id': restaurantId,
        'user_id': uid,
      });

      return Success(restaurantId);
    } catch (e) {
      return Failure('Failed to create restaurant: ${e.toString()}');
    }
  }

  Future<Result<List<Promotion>>> getPromotions(String restaurantId) async {
    try {
      final rows = await _client.supabaseClient.client
          .from('promotions')
          .select()
          .eq('restaurant_id', restaurantId)
          .order('starts_at', ascending: false);
      final data = (rows as List)
          .map((row) => Promotion.fromMap(row as Map<String, dynamic>))
          .toList();
      return Success(data);
    } catch (e) {
      return Failure('Failed to load promotions: $e');
    }
  }

  Future<Result<void>> deletePromotion(String promotionId) async {
    try {
      await _client.supabaseClient.client
          .from('promotions')
          .delete()
          .eq('id', promotionId);
      return const Success(null);
    } catch (e) {
      return Failure('Failed to delete promotion: $e');
    }
  }
}
