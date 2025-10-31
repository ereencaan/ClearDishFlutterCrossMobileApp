import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cleardish/features/onboarding/controllers/onboarding_controller.dart';
import 'package:cleardish/features/profile/controllers/profile_controller.dart';
import 'package:cleardish/data/models/allergen.dart';
import 'package:cleardish/widgets/app_button.dart';
import 'package:cleardish/widgets/chips_filter.dart';

/// Onboarding screen
/// 
/// Allows users to select allergens and dietary preferences.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  @override
  void initState() {
    super.initState();
    // Load existing profile if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        ref.read(profileControllerProvider.notifier).loadProfile(user.id);
      }
    });
  }

  Future<void> _handleContinue() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      context.go('/login');
      return;
    }

    final onboardingState = ref.read(onboardingControllerProvider);
    final profileController = ref.read(profileControllerProvider.notifier);

    // Save allergens
    if (onboardingState.selectedAllergens.isNotEmpty) {
      await profileController.updateAllergens(
        user.id,
        onboardingState.selectedAllergens,
      );
    }

    // Save diets
    if (onboardingState.selectedDiets.isNotEmpty) {
      await profileController.updateDiets(
        user.id,
        onboardingState.selectedDiets,
      );
    }

    if (!mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(onboardingControllerProvider);
    final onboardingController = ref.read(onboardingControllerProvider.notifier);

    final allergenItems = Allergen.standardAllergens.map((a) => a.name).toList();
    final dietItems = Allergen.standardDiets.map((d) => d.name).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Up Your Profile'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Welcome to ClearDish',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tell us about your allergens and dietary preferences',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              ChipsFilter(
                label: 'Allergens',
                items: allergenItems,
                selectedItems: onboardingState.selectedAllergens,
                onSelectionChanged: (selected) {
                  onboardingController.updateAllergens(selected);
                },
              ),
              const SizedBox(height: 32),
              ChipsFilter(
                label: 'Dietary Preferences',
                items: dietItems,
                selectedItems: onboardingState.selectedDiets,
                onSelectionChanged: (selected) {
                  onboardingController.updateDiets(selected);
                },
              ),
              const SizedBox(height: 48),
              AppButton(
                label: 'Continue',
                onPressed: _handleContinue,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/home'),
                child: const Text('Skip for now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

