import 'package:equatable/equatable.dart';

/// User profile model
/// 
/// Represents user profile data including allergens and dietary preferences.
class UserProfile extends Equatable {
  const UserProfile({
    required this.userId,
    this.fullName,
    this.allergens = const [],
    this.diets = const [],
  });

  final String userId;
  final String? fullName;
  final List<String> allergens;
  final List<String> diets;

  /// Creates UserProfile from Supabase map
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      userId: map['user_id'] as String,
      fullName: map['full_name'] as String?,
      allergens: List<String>.from(
        (map['allergens'] as List<dynamic>?) ?? [],
      ),
      diets: List<String>.from(
        (map['diets'] as List<dynamic>?) ?? [],
      ),
    );
  }

  /// Converts UserProfile to Supabase map
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'full_name': fullName,
      'allergens': allergens,
      'diets': diets,
    };
  }

  /// Creates a copy with optional overrides
  UserProfile copyWith({
    String? userId,
    String? fullName,
    List<String>? allergens,
    List<String>? diets,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      allergens: allergens ?? this.allergens,
      diets: diets ?? this.diets,
    );
  }

  @override
  List<Object?> get props => [userId, fullName, allergens, diets];
}

