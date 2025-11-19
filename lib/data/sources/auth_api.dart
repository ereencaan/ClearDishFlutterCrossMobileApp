import 'package:supabase_flutter/supabase_flutter.dart' as supabase
    hide SupabaseClient;
import 'package:cleardish/core/utils/result.dart';
import 'package:cleardish/data/sources/supabase_client.dart' as app;

/// Authentication API
///
/// Handles authentication operations with Supabase Auth.
class AuthApi {
  AuthApi(this._client);
  final app.SupabaseClient _client;

  /// Gets current user
  supabase.User? get currentUser => _client.auth.currentUser;

  /// Stream of auth state changes
  Stream<supabase.AuthState> get authStateChanges =>
      _client.auth.onAuthStateChange;

  /// Signs in with email and password
  Future<Result<supabase.Session>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return Success(response.session!);
    } on supabase.AuthException catch (e) {
      return Failure(e.message);
    } catch (e) {
      return Failure('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Registers a new user with optional user metadata
  Future<Result<supabase.Session>> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Normalize email input early
      final normalizedEmail = email.trim().toLowerCase();
      final response = await _client.auth.signUp(
        email: normalizedEmail,
        password: password,
        data: data,
      );
      // Many Supabase projects require email confirmation. In that case
      // session will be null even though the request is successful.
      if (response.session == null) {
        return const Failure(
          'Check your inbox to confirm your email, then sign in.',
        );
      }
      return Success(response.session!);
    } on supabase.AuthException catch (e) {
      return Failure(e.message);
    } catch (e) {
      return Failure('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Signs out current user
  Future<Result<void>> signOut() async {
    try {
      await _client.auth.signOut();
      return const Success(null);
    } catch (e) {
      return Failure('Failed to sign out: ${e.toString()}');
    }
  }
}
