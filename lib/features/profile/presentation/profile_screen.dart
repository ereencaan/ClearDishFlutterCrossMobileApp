import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cleardish/features/profile/controllers/profile_controller.dart';
import 'package:cleardish/features/auth/controllers/auth_controller.dart';
import 'package:cleardish/core/utils/result.dart';
import 'package:cleardish/data/models/allergen.dart';
import 'package:cleardish/widgets/app_button.dart';
import 'package:cleardish/widgets/chips_filter.dart';

/// Profile screen
///
/// Allows users to view and edit their profile, allergens, and diets.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      await ref.read(profileControllerProvider.notifier).loadProfile(user.id);
      final profile = ref.read(profileControllerProvider).profile;
      if (profile?.fullName != null) {
        _nameController.text = profile!.fullName!;
      }
    }
  }

  Future<void> _handleSave() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      context.go('/login');
      return;
    }

    final profileController = ref.read(profileControllerProvider.notifier);
    final profile = ref.read(profileControllerProvider).profile;

    if (profile == null) {
      return;
    }

    final updatedProfile = profile.copyWith(
      fullName: _nameController.text.trim().isEmpty
          ? null
          : _nameController.text.trim(),
    );

    final result = await profileController.saveProfile(updatedProfile);

    if (!mounted) return;

    if (result.isFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorOrNull ?? 'Failed to save profile'),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _handleLogout() async {
    final result = await ref.read(authControllerProvider.notifier).signOut();
    if (!mounted) return;

    if (result.isFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorOrNull ?? 'Failed to sign out'),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileControllerProvider);
    final user = Supabase.instance.client.auth.currentUser;

    if (profileState.isLoading && profileState.profile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final profile = profileState.profile;
    final allergenItems = Allergen.standardAllergens.map((a) => a.name).toList();
    final dietItems = Allergen.standardDiets.map((d) => d.name).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              ChipsFilter(
                label: 'Allergens',
                items: allergenItems,
                selectedItems: profile?.allergens ?? [],
                onSelectionChanged: (selected) async {
                  if (user != null) {
                    await ref
                        .read(profileControllerProvider.notifier)
                        .updateAllergens(user.id, selected);
                  }
                },
              ),
              const SizedBox(height: 24),
              ChipsFilter(
                label: 'Dietary Preferences',
                items: dietItems,
                selectedItems: profile?.diets ?? [],
                onSelectionChanged: (selected) async {
                  if (user != null) {
                    await ref
                        .read(profileControllerProvider.notifier)
                        .updateDiets(user.id, selected);
                  }
                },
              ),
              const SizedBox(height: 32),
              AppButton(
                label: 'Save Profile',
                isLoading: profileState.isSaving,
                onPressed: _handleSave,
              ),
              const SizedBox(height: 16),
              AppButton(
                label: 'Sign Out',
                isOutlined: true,
                onPressed: _handleLogout,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
