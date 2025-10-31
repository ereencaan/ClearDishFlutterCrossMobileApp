import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cleardish/data/repositories/auth_repo.dart';
import 'package:cleardish/core/utils/result.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Auth repository provider
final authRepoProvider = Provider<AuthRepo>((ref) {
  return AuthRepo();
});

/// Auth controller state
class AuthState {
  const AuthState({
    this.isLoading = false,
    this.error,
    this.user,
  });

  final bool isLoading;
  final String? error;
  final User? user;

  AuthState copyWith({
    bool? isLoading,
    String? error,
    User? user,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      user: user ?? this.user,
    );
  }
}

/// Auth controller
class AuthController extends StateNotifier<AuthState> {
  AuthController(this._authRepo) : super(const AuthState()) {
    _initialize();
  }

  final AuthRepo _authRepo;

  void _initialize() {
    state = state.copyWith(user: _authRepo.currentUser);
    _authRepo.authStateChanges.listen((authState) {
      state = state.copyWith(
        user: authState.session?.user,
      );
    });
  }

  /// Logs in with email and password
  Future<Result<void>> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _authRepo.login(email: email, password: password);
    state = state.copyWith(
      isLoading: false,
      error: result.isFailure ? result.errorOrNull : null,
      user: result.isSuccess ? _authRepo.currentUser : null,
    );
    return result.map((_) => null);
  }

  /// Registers a new user
  Future<Result<void>> register({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _authRepo.register(email: email, password: password);
    state = state.copyWith(
      isLoading: false,
      error: result.isFailure ? result.errorOrNull : null,
      user: result.isSuccess ? _authRepo.currentUser : null,
    );
    return result.map((_) => null);
  }

  /// Signs out current user
  Future<Result<void>> signOut() async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _authRepo.signOut();
    state = state.copyWith(
      isLoading: false,
      error: result.isFailure ? result.errorOrNull : null,
      user: null,
    );
    return result;
  }
}

/// Auth controller provider
final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(authRepoProvider));
});

