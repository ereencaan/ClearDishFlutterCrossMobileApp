import 'package:cleardish/core/utils/result.dart';
import 'package:cleardish/data/sources/supabase_client.dart';

class TimePoint {
  const TimePoint(this.label, this.value);
  final String label; // e.g. 2025-11-01
  final int value;
}

class TopEntry {
  const TopEntry(this.label, this.value);
  final String label;
  final int value;
}

class AnalyticsApi {
  AnalyticsApi(this._client);
  final SupabaseClient _client;

  Future<Result<List<TimePoint>>> loginsByDay({int days = 30}) async {
    try {
      final rows = await _client.supabaseClient.client
          .rpc('analytics_logins_by_day', params: {'p_days': days});
      final list = (rows as List)
          .map((e) => TimePoint(
                (e['day'] as String?) ?? e['day'].toString(),
                (e['count'] as num).toInt(),
              ))
          .toList();
      return Success(list);
    } catch (e) {
      return Failure('Failed to load login series: ${e.toString()}');
    }
  }

  Future<Result<List<TimePoint>>> searchesByDay({int days = 30}) async {
    try {
      final rows = await _client.supabaseClient.client
          .rpc('analytics_searches_by_day', params: {'p_days': days});
      final list = (rows as List)
          .map((e) => TimePoint(
                (e['day'] as String?) ?? e['day'].toString(),
                (e['count'] as num).toInt(),
              ))
          .toList();
      return Success(list);
    } catch (e) {
      return Failure('Failed to load search series: ${e.toString()}');
    }
  }

  Future<Result<List<TopEntry>>> topRestaurants({int limit = 10}) async {
    try {
      final rows = await _client.supabaseClient.client
          .from('analytics_top_restaurants')
          .select()
          .limit(limit);
      final list = (rows as List)
          .map((e) => TopEntry(
                (e['name'] as String?) ?? 'Unknown',
                (e['count'] as num).toInt(),
              ))
          .toList();
      return Success(list);
    } catch (e) {
      return Failure('Failed to load top restaurants: ${e.toString()}');
    }
  }

  Future<Result<List<TopEntry>>> topUsers({int limit = 10}) async {
    try {
      final rows = await _client.supabaseClient.client
          .from('analytics_top_users')
          .select()
          .limit(limit);
      final list = (rows as List)
          .map((e) => TopEntry(
                (e['email'] as String?) ?? 'User',
                (e['count'] as num).toInt(),
              ))
          .toList();
      return Success(list);
    } catch (e) {
      return Failure('Failed to load top users: ${e.toString()}');
    }
  }
}
