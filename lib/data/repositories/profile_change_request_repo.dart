import 'package:cleardish/core/utils/result.dart';
import 'package:cleardish/data/models/profile_change_request.dart';
import 'package:cleardish/data/sources/supabase_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Repository for persisting allergen/diet change requests.
class ProfileChangeRequestRepo {
  ProfileChangeRequestRepo()
      : _client = SupabaseClient.instance.supabaseClient.client,
        _auth = SupabaseClient.instance.auth;

  final supabase.SupabaseClient _client;
  final supabase.GoTrueClient _auth;

  /// Loads all pending requests for current admins.
  Future<Result<List<ProfileChangeRequest>>> getPendingRequests() async {
    try {
      final rows = await _client
          .from('profile_change_requests')
          .select()
          .eq('status', ProfileChangeRequestStatus.pending.value)
          .order('requested_at', ascending: false);
      final data = (rows as List<dynamic>)
          .map((row) =>
              ProfileChangeRequest.fromMap(row as Map<String, dynamic>))
          .toList();
      return Success(data);
    } catch (e) {
      return Failure('Failed to load pending change requests: $e');
    }
  }

  /// Loads pending requests for a single user.
  Future<Result<List<ProfileChangeRequest>>> getPendingRequestsForUser(
    String userId,
  ) async {
    try {
      final rows = await _client
          .from('profile_change_requests')
          .select()
          .eq('user_id', userId)
          .eq('status', ProfileChangeRequestStatus.pending.value)
          .order('requested_at', ascending: false);
      final data = (rows as List<dynamic>)
          .map((row) =>
              ProfileChangeRequest.fromMap(row as Map<String, dynamic>))
          .toList();
      return Success(data);
    } catch (e) {
      return Failure('Failed to load your pending requests: $e');
    }
  }

  /// Submits a new change request, replacing any existing pending entry.
  Future<Result<ProfileChangeRequest>> submitRequest({
    required String userId,
    required ProfileChangeRequestType type,
    required List<String> requestedValues,
  }) async {
    try {
      await _client
          .from('profile_change_requests')
          .delete()
          .eq('user_id', userId)
          .eq('type', type.value)
          .eq('status', ProfileChangeRequestStatus.pending.value);

      String? userName;
      try {
        final profile = await _client
            .from('user_profiles')
            .select('full_name')
            .eq('user_id', userId)
            .maybeSingle();
        userName = profile?['full_name'] as String?;
      } catch (_) {
        userName = null;
      }

      final response = await _client
          .from('profile_change_requests')
          .insert({
            'user_id': userId,
            'type': type.value,
            'requested_values': requestedValues,
            'status': ProfileChangeRequestStatus.pending.value,
            'user_name_snapshot': userName,
            'user_email_snapshot': _auth.currentUser?.email,
          })
          .select()
          .single();

      return Success(ProfileChangeRequest.fromMap(response));
    } catch (e) {
      return Failure(
        'Failed to submit ${type.value} change request: $e',
      );
    }
  }

  /// Approves a change and syncs the user profile field.
  Future<Result<void>> approveRequest({
    required String requestId,
    required String adminId,
    String? adminNote,
  }) async {
    try {
      final row = await _client
          .from('profile_change_requests')
          .select()
          .eq('id', requestId)
          .maybeSingle();
      if (row == null) {
        return const Failure('Request not found');
      }
      final request = ProfileChangeRequest.fromMap(row);
      if (request.status != ProfileChangeRequestStatus.pending) {
        return const Failure('Request already processed');
      }

      final column = request.type == ProfileChangeRequestType.allergens
          ? 'allergens'
          : 'diets';

      await _client.from('user_profiles').upsert({
        'user_id': request.userId,
        column: request.requestedValues,
      });

      await _client.from('profile_change_requests').update({
        'status': ProfileChangeRequestStatus.approved.value,
        'resolved_at': DateTime.now().toUtc().toIso8601String(),
        'resolved_by': adminId,
        'admin_note': adminNote,
      }).eq('id', requestId);

      return const Success(null);
    } catch (e) {
      return Failure('Failed to approve request: $e');
    }
  }

  /// Rejects a pending change request.
  Future<Result<void>> rejectRequest({
    required String requestId,
    required String adminId,
    String? adminNote,
  }) async {
    try {
      await _client.from('profile_change_requests').update({
        'status': ProfileChangeRequestStatus.rejected.value,
        'resolved_at': DateTime.now().toUtc().toIso8601String(),
        'resolved_by': adminId,
        'admin_note': adminNote,
      }).eq('id', requestId);
      return const Success(null);
    } catch (e) {
      return Failure('Failed to reject request: $e');
    }
  }
}

/// Provider for dependency injection.
final profileChangeRequestRepoProvider =
    Provider<ProfileChangeRequestRepo>((ref) {
  return ProfileChangeRequestRepo();
});
