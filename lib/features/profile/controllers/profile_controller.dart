import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cleardish/core/utils/result.dart';
import 'package:cleardish/data/models/profile_change_request.dart';
import 'package:cleardish/data/models/user_profile.dart';
import 'package:cleardish/data/repositories/profile_change_request_repo.dart';
import 'package:cleardish/data/repositories/profile_repo.dart';

/// Profile repository provider
final profileRepoProvider = Provider<ProfileRepo>((ref) {
  return ProfileRepo();
});

const _profileStateSentinel = Object();

/// Profile controller state
class ProfileState {
  const ProfileState({
    this.isLoading = false,
    this.isSaving = false,
    this.isSubmittingChange = false,
    this.error,
    this.profile,
    this.pendingAllergenRequest,
    this.pendingDietRequest,
  });

  final bool isLoading;
  final bool isSaving;
  final bool isSubmittingChange;
  final String? error;
  final UserProfile? profile;
  final ProfileChangeRequest? pendingAllergenRequest;
  final ProfileChangeRequest? pendingDietRequest;

  ProfileState copyWith({
    bool? isLoading,
    bool? isSaving,
    bool? isSubmittingChange,
    String? error,
    UserProfile? profile,
    Object? pendingAllergenRequest = _profileStateSentinel,
    Object? pendingDietRequest = _profileStateSentinel,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isSubmittingChange: isSubmittingChange ?? this.isSubmittingChange,
      error: error,
      profile: profile ?? this.profile,
      pendingAllergenRequest: identical(
        pendingAllergenRequest,
        _profileStateSentinel,
      )
          ? this.pendingAllergenRequest
          : pendingAllergenRequest as ProfileChangeRequest?,
      pendingDietRequest: identical(pendingDietRequest, _profileStateSentinel)
          ? this.pendingDietRequest
          : pendingDietRequest as ProfileChangeRequest?,
    );
  }
}

/// Profile controller
class ProfileController extends StateNotifier<ProfileState> {
  ProfileController(
    this._profileRepo,
    this._changeRequestRepo,
  ) : super(const ProfileState());

  final ProfileRepo _profileRepo;
  final ProfileChangeRequestRepo _changeRequestRepo;

  /// Loads profile for current user
  Future<Result<void>> loadProfile(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    final profileResult = await _profileRepo.getProfile(userId);
    final pendingResult =
        await _changeRequestRepo.getPendingRequestsForUser(userId);
    state = state.copyWith(
      isLoading: false,
      error: profileResult.errorOrNull ?? pendingResult.errorOrNull,
      profile: profileResult.dataOrNull,
      pendingAllergenRequest: _findRequestOfType(
        pendingResult.dataOrNull,
        ProfileChangeRequestType.allergens,
      ),
      pendingDietRequest: _findRequestOfType(
        pendingResult.dataOrNull,
        ProfileChangeRequestType.diets,
      ),
    );
    return profileResult.map((_) {});
  }

  /// Updates allergens list directly (used during onboarding/initial save)
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
    await _refreshPendingRequests(userId);
    return result.map((_) {});
  }

  /// Updates diets list directly (used during onboarding/initial save)
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
    await _refreshPendingRequests(userId);
    return result.map((_) {});
  }

  /// Requests an admin-approved allergen change.
  Future<Result<void>> requestAllergenChange(
    String userId,
    List<String> allergens,
  ) async {
    state = state.copyWith(isSubmittingChange: true, error: null);
    final result = await _changeRequestRepo.submitRequest(
      userId: userId,
      type: ProfileChangeRequestType.allergens,
      requestedValues: allergens,
    );
    state = state.copyWith(
      isSubmittingChange: false,
      error: result.errorOrNull,
    );
    await _refreshPendingRequests(userId);
    return result.map((_) {});
  }

  /// Requests an admin-approved diet change.
  Future<Result<void>> requestDietChange(
    String userId,
    List<String> diets,
  ) async {
    state = state.copyWith(isSubmittingChange: true, error: null);
    final result = await _changeRequestRepo.submitRequest(
      userId: userId,
      type: ProfileChangeRequestType.diets,
      requestedValues: diets,
    );
    state = state.copyWith(
      isSubmittingChange: false,
      error: result.errorOrNull,
    );
    await _refreshPendingRequests(userId);
    return result.map((_) {});
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
    return result.map((_) {});
  }

  ProfileChangeRequest? _findRequestOfType(
    List<ProfileChangeRequest>? requests,
    ProfileChangeRequestType type,
  ) {
    if (requests == null) return null;
    for (final request in requests) {
      if (request.type == type &&
          request.status == ProfileChangeRequestStatus.pending) {
        return request;
      }
    }
    return null;
  }

  Future<void> _refreshPendingRequests(String userId) async {
    final pendingResult =
        await _changeRequestRepo.getPendingRequestsForUser(userId);
    if (pendingResult.isFailure) return;
    final requests = pendingResult.dataOrNull ?? [];
    state = state.copyWith(
      pendingAllergenRequest: _findRequestOfType(
        requests,
        ProfileChangeRequestType.allergens,
      ),
      pendingDietRequest: _findRequestOfType(
        requests,
        ProfileChangeRequestType.diets,
      ),
    );
  }
}

/// Profile controller provider
final profileControllerProvider =
    StateNotifierProvider<ProfileController, ProfileState>((ref) {
  return ProfileController(
    ref.watch(profileRepoProvider),
    ref.watch(profileChangeRequestRepoProvider),
  );
});
