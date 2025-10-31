import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cleardish/data/repositories/profile_repo.dart';
import 'package:cleardish/data/models/user_profile.dart';
import 'package:cleardish/core/utils/result.dart';

/// Profile repository provider
final profileRepoProvider = Provider<ProfileRepo>((ref) {
  return ProfileRepo();
});

/// Profile controller state
class ProfileState {
  const ProfileState({
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.profile,
  });

  final bool isLoading;
  final bool isSaving;
  final String? error;
  final UserProfile? profile;

  ProfileState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? error,
    UserProfile? profile,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error,
      profile: profile ?? this.profile,
    );
  }
}

/// Profile controller
class ProfileController extends StateNotifier<ProfileState> {
  ProfileController(this._profileRepo) : super(const ProfileState());

  final ProfileRepo _profileRepo;

  /// Loads profile for current user
  Future<Result<void>> loadProfile(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _profileRepo.getProfile(userId);
    state = state.copyWith(
      isLoading: false,
      error: result.isFailure ? result.errorOrNull : null,
      profile: result.dataOrNull,
    );
    return result.map((_) => null);
  }

  /// Updates allergens list
  Future<Result<void>> updateAllergens(
    String userId,
    List<String> allergens,
  ) async {
    state = state.copyWith(isSaving: true, error: null);
    final result = await _profileRepo.updateAllergens(userId, allergens);
    state = state.copyWith(
      isSaving: false,
      error: result.isFailure ? result.errorOrNull : null,
      profile: result.dataOrNull,
    );
    return result.map((_) => null);
  }

  /// Updates diets list
  Future<Result<void>> updateDiets(
    String userId,
    List<String> diets,
  ) async {
    state = state.copyWith(isSaving: true, error: null);
    final result = await _profileRepo.updateDiets(userId, diets);
    state = state.copyWith(
      isSaving: false,
      error: result.isFailure ? result.errorOrNull : null,
      profile: result.dataOrNull,
    );
    return result.map((_) => null);
  }

  /// Saves full profile
  Future<Result<void>> saveProfile(UserProfile profile) async {
    state = state.copyWith(isSaving: true, error: null);
    final result = await _profileRepo.saveProfile(profile);
    state = state.copyWith(
      isSaving: false,
      error: result.isFailure ? result.errorOrNull : null,
      profile: result.dataOrNull,
    );
    return result.map((_) => null);
  }
}

/// Profile controller provider
final profileControllerProvider =
    StateNotifierProvider<ProfileController, ProfileState>((ref) {
  return ProfileController(ref.watch(profileRepoProvider));
});

