import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cleardish/data/repositories/profile_repo.dart';
import 'package:cleardish/data/models/user_profile.dart';
import 'package:cleardish/core/utils/result.dart';

// Note: This is a basic test structure. For full testing, you would need
// to set up mocks for Supabase client. This test demonstrates the pattern.

void main() {
  group('Profile Save Tests', () {
    test('Profile model can be created and converted to/from map', () {
      const profile = UserProfile(
        userId: 'test-user-id',
        fullName: 'Test User',
        allergens: ['gluten', 'peanut'],
        diets: ['vegan'],
      );

      final map = profile.toMap();
      final restored = UserProfile.fromMap(map);

      expect(restored.userId, equals(profile.userId));
      expect(restored.fullName, equals(profile.fullName));
      expect(restored.allergens, equals(profile.allergens));
      expect(restored.diets, equals(profile.diets));
    });

    test('Profile copyWith creates new instance with updated fields', () {
      const original = UserProfile(
        userId: 'test-user-id',
        fullName: 'Test User',
        allergens: ['gluten'],
      );

      final updated = original.copyWith(allergens: ['gluten', 'peanut']);

      expect(updated.allergens, equals(['gluten', 'peanut']));
      expect(original.allergens, equals(['gluten'])); // Original unchanged
      expect(updated.userId, equals(original.userId));
    });
  });
}


