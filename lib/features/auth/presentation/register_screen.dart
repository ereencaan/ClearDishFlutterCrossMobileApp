import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cleardish/features/auth/controllers/auth_controller.dart';
import 'package:cleardish/features/auth/models/auth_role.dart';
import 'package:cleardish/core/utils/result.dart';
import 'package:cleardish/widgets/app_button.dart';
import 'package:cleardish/widgets/app_input.dart';
import 'package:cleardish/data/models/allergen.dart';
import 'package:cleardish/widgets/chips_filter.dart';
import 'package:cleardish/data/models/user_profile.dart';
import 'package:cleardish/data/repositories/profile_repo.dart';
import 'package:cleardish/data/sources/restaurant_settings_api.dart';
import 'package:cleardish/data/sources/supabase_client.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Register screen
///
/// Allows users to create a new account.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key, this.role = AuthRole.user});

  final AuthRole role;

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  // User profile fields
  final _fullNameController = TextEditingController();
  final _addressController = TextEditingController();
  XFile? _pickedAvatar;
  List<String> _selectedAllergens = [];
  List<String> _selectedDiets = [];
  // Restaurant fields
  final _restaurantNameController = TextEditingController();
  final _restaurantAddressController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _addressController.dispose();
    _restaurantNameController.dispose();
    _restaurantAddressController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final result = await ref.read(authControllerProvider.notifier).register(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          role: widget.role,
        );

    if (!mounted) return;

    if (result.isFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorOrNull ?? 'Registration failed'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Post-register actions per role
    if (widget.role == AuthRole.user) {
      final uid = SupabaseClient.instance.auth.currentUser?.id;
      if (uid != null) {
        String? avatarUrl;
        if (_pickedAvatar != null) {
          try {
            final bytes = await _pickedAvatar!.readAsBytes();
            final filePath =
                'avatars/$uid-${DateTime.now().millisecondsSinceEpoch}.jpg';
            await SupabaseClient.instance.supabaseClient.client.storage
                .from('avatars')
                .uploadBinary(filePath, bytes,
                    fileOptions: const supabase.FileOptions(upsert: true));
            avatarUrl = SupabaseClient.instance.supabaseClient.client.storage
                .from('avatars')
                .getPublicUrl(filePath);
          } catch (_) {
            avatarUrl = null;
          }
        }
        final profileRepo = ref.read(profileRepoProvider);
        await profileRepo.saveProfile(
          UserProfile(
            userId: uid,
            fullName: _fullNameController.text.trim().isEmpty
                ? null
                : _fullNameController.text.trim(),
            address: _addressController.text.trim().isEmpty
                ? null
                : _addressController.text.trim(),
            avatarUrl: avatarUrl,
            allergens: _selectedAllergens,
            diets: _selectedDiets,
          ),
        );
      }
      context.go('/home');
      return;
    }

    if (widget.role == AuthRole.restaurant) {
      final api = RestaurantSettingsApi(SupabaseClient.instance);
      await api.createRestaurantWithOwner(
        name: _restaurantNameController.text.trim(),
        address: _restaurantAddressController.text.trim(),
      );
      context.go('/home/restaurant/settings');
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    final isRestaurant = widget.role == AuthRole.restaurant;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          // soft gradient background (mirrors welcome)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFE9F8EF), Color(0xFFCFF3DA)],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: Card(
                    color: Colors.black.withOpacity(0.88),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor:
                                      colorScheme.primary.withOpacity(0.15),
                                  child: Icon(
                                    isRestaurant
                                        ? Icons.storefront
                                        : Icons.person,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  isRestaurant
                                      ? 'Create Restaurant Account'
                                      : 'Create Account',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Sign up to get started',
                              style: TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 24),
                            // email / password
                            AppInput(
                              label: 'Email',
                              keyboardType: TextInputType.emailAddress,
                              controller: _emailController,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!value.contains('@')) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            AppInput(
                              label: 'Password',
                              obscureText: true,
                              controller: _passwordController,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            AppInput(
                              label: 'Confirm Password',
                              obscureText: true,
                              controller: _confirmPasswordController,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please confirm your password';
                                }
                                if (value != _passwordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Role-specific fields
                            if (!isRestaurant) ...[
                              AppInput(
                                label: 'Full Name',
                                controller: _fullNameController,
                              ),
                              const SizedBox(height: 12),
                              AppInput(
                                label: 'Address',
                                controller: _addressController,
                              ),
                              const SizedBox(height: 12),
                              _AvatarPicker(
                                picked: _pickedAvatar,
                                onPick: (x) =>
                                    setState(() => _pickedAvatar = x),
                              ),
                              const SizedBox(height: 16),
                              ChipsFilter(
                                label: 'Allergens',
                                items: Allergen.standardAllergens
                                    .map((a) => a.id)
                                    .toList(),
                                selectedItems: _selectedAllergens,
                                onSelectionChanged: (s) {
                                  setState(() => _selectedAllergens = s);
                                },
                              ),
                              const SizedBox(height: 16),
                              ChipsFilter(
                                label: 'Dietary Preferences',
                                items: Allergen.standardDiets
                                    .map((d) => d.id)
                                    .toList(),
                                selectedItems: _selectedDiets,
                                onSelectionChanged: (s) {
                                  setState(() => _selectedDiets = s);
                                },
                              ),
                            ] else ...[
                              AppInput(
                                label: 'Restaurant Name',
                                controller: _restaurantNameController,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Please enter a restaurant name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              AppInput(
                                label: 'Restaurant Address',
                                controller: _restaurantAddressController,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Please enter an address';
                                  }
                                  return null;
                                },
                              ),
                            ],

                            const SizedBox(height: 20),
                            AppButton(
                              label: 'Sign Up',
                              isLoading: authState.isLoading,
                              onPressed: _handleRegister,
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () => context.go(
                                isRestaurant
                                    ? '/login/restaurant'
                                    : '/login/user',
                              ),
                              child: const Text(
                                  'Already have an account? Sign In'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({required this.picked, required this.onPick});
  final XFile? picked;
  final ValueChanged<XFile?> onPick;

  Future<void> _choose(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
        source: source, maxWidth: 1024, maxHeight: 1024, imageQuality: 85);
    onPick(file);
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  void _showSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take a photo'),
              onTap: () => _choose(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () => _choose(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          child: picked == null
              ? const Icon(Icons.person)
              : const Icon(Icons.check),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: () => _showSheet(context),
          icon: const Icon(Icons.upload),
          label: const Text('Upload Photo'),
        ),
      ],
    );
  }
}
