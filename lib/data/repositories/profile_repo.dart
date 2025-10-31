import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cleardish/core/utils/result.dart';
import 'package:cleardish/data/models/user_profile.dart';
import 'package:cleardish/data/sources/supabase_client.dart';

/// Profile repository
/// 
/// Handles user profile operations with Supabase.
class ProfileRepo {
  ProfileRepo() : _client = SupabaseClient.instance;

  final SupabaseClient _client;

  /// Gets user profile by user ID
  Future<Result<UserProfile>> getProfile(String userId) async {
    try {
      final response = await _client.supabaseClient.client.from('user_profiles').select().eq(
            'user_id',
            userId,
          ).maybeSingle();

      if (response == null) {
        // Profile doesn't exist, return empty profile
        return Success(
          UserProfile(userId: userId),
        );
      }

      final profile = UserProfile.fromMap(
        response as Map<String, dynamic>,
      );

      return Success(profile);
    } catch (e) {
      return Failure('Failed to fetch profile: ${e.toString()}');
    }
  }

  /// Creates or updates user profile
  Future<Result<UserProfile>> saveProfile(UserProfile profile) async {
    try {
      await _client.supabaseClient.client.from('user_profiles').upsert(
            profile.toMap(),
          );

      return Success(profile);
    } catch (e) {
      return Failure('Failed to save profile: ${e.toString()}');
    }
  }

  /// Updates allergens list
  Future<Result<UserProfile>> updateAllergens(
    String userId,
    List<String> allergens,
  ) async {
    final profileResult = await getProfile(userId);
    if (profileResult.isFailure) {
      return Failure(profileResult.errorOrNull!);
    }

    final profile = profileResult.dataOrNull!;
    final updatedProfile = profile.copyWith(allergens: allergens);

    return saveProfile(updatedProfile);
  }

  /// Updates diets list
  Future<Result<UserProfile>> updateDiets(
    String userId,
    List<String> diets,
  ) async {
    final profileResult = await getProfile(userId);
    if (profileResult.isFailure) {
      return Failure(profileResult.errorOrNull!);
    }

    final profile = profileResult.dataOrNull!;
    final updatedProfile = profile.copyWith(diets: diets);

    return saveProfile(updatedProfile);
  }
}

