import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cleardish/features/onboarding/controllers/onboarding_controller.dart';
import 'package:cleardish/features/profile/controllers/profile_controller.dart';
import 'package:cleardish/data/models/user_profile.dart';
import 'package:cleardish/data/models/allergen.dart';
import 'package:cleardish/widgets/app_button.dart';
import 'package:cleardish/widgets/chips_filter.dart';
import 'package:cleardish/widgets/app_back_button.dart';

/// Onboarding screen
///
/// Allows users to select allergens and dietary preferences.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _avatarUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load existing profile if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        ref.read(profileControllerProvider.notifier).loadProfile(user.id);
        final profile = ref.read(profileControllerProvider).profile;
        if (profile != null) {
          _nameController.text = profile.fullName ?? '';
          _addressController.text = profile.address ?? '';
          _avatarUrlController.text = profile.avatarUrl ?? '';
        }
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
    final existing = ref.read(profileControllerProvider).profile;

    final profile = UserProfile(
      userId: user.id,
      fullName: _nameController.text.trim().isEmpty
          ? existing?.fullName
          : _nameController.text.trim(),
      address: _addressController.text.trim().isEmpty
          ? existing?.address
          : _addressController.text.trim(),
      avatarUrl: _avatarUrlController.text.trim().isEmpty
          ? existing?.avatarUrl
          : _avatarUrlController.text.trim(),
      allergens: existing?.allergens ?? const [],
      diets: existing?.diets ?? const [],
    );

    await profileController.saveProfile(profile);

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
    final onboardingController =
        ref.read(onboardingControllerProvider.notifier);

    final allergenItems =
        Allergen.standardAllergens.map((a) => a.name).toList();
    final dietItems = Allergen.standardDiets.map((d) => d.name).toList();

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallbackRoute: '/home'),
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
                'Tell us about yourself and your preferences',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _avatarUrlController,
                decoration: const InputDecoration(
                  labelText: 'Photo URL (optional)',
                ),
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
