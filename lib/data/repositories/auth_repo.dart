import 'package:cleardish/data/sources/auth_api.dart';
import 'package:cleardish/data/sources/supabase_client.dart';
import 'package:cleardish/core/utils/result.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Authentication repository
/// 
/// Provides authentication operations and state management.
class AuthRepo {
  AuthRepo() : _api = AuthApi(SupabaseClient.instance);

  final AuthApi _api;

  /// Gets current user
  User? get currentUser => _api.currentUser;

  /// Stream of auth state changes
  Stream<AuthState> get authStateChanges => _api.authStateChanges;

  /// Signs in with email and password
  Future<Result<Session>> login({
    required String email,
    required String password,
  }) async {
    return _api.signIn(email: email, password: password);
  }

  /// Registers a new user
  Future<Result<Session>> register({
    required String email,
    required String password,
  }) async {
    return _api.signUp(email: email, password: password);
  }

  /// Signs out current user
  Future<Result<void>> signOut() async {
    return _api.signOut();
  }
}

