import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Onboarding controller state
class OnboardingState {
  const OnboardingState({
    this.selectedAllergens = const [],
    this.selectedDiets = const [],
  });

  final List<String> selectedAllergens;
  final List<String> selectedDiets;

  OnboardingState copyWith({
    List<String>? selectedAllergens,
    List<String>? selectedDiets,
  }) {
    return OnboardingState(
      selectedAllergens: selectedAllergens ?? this.selectedAllergens,
      selectedDiets: selectedDiets ?? this.selectedDiets,
    );
  }
}

/// Onboarding controller
class OnboardingController extends StateNotifier<OnboardingState> {
  OnboardingController() : super(const OnboardingState());

  /// Updates selected allergens
  void updateAllergens(List<String> allergens) {
    state = state.copyWith(selectedAllergens: allergens);
  }

  /// Updates selected diets
  void updateDiets(List<String> diets) {
    state = state.copyWith(selectedDiets: diets);
  }
}

/// Onboarding controller provider
final onboardingControllerProvider =
    StateNotifierProvider<OnboardingController, OnboardingState>((ref) {
  return OnboardingController();
});
