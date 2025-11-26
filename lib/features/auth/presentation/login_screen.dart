import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cleardish/features/auth/controllers/auth_controller.dart';
import 'package:cleardish/features/auth/models/auth_role.dart';
import 'package:cleardish/core/utils/result.dart';
import 'package:cleardish/widgets/app_button.dart';
import 'package:cleardish/widgets/app_input.dart';
import 'package:cleardish/widgets/brand_logo.dart';

/// Login screen
///
/// Allows users to sign in with email and password.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.role = AuthRole.user});

  final AuthRole role;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final result = await ref.read(authControllerProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          expectedRole: widget.role,
        );

    if (!mounted) return;

    if (result.isFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorOrNull ?? 'Login failed'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Navigate to a unified soft loading screen; it will forward by role.
    final user = ref.read(authControllerProvider).user;
    if (user != null) context.go('/loading');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const BrandLogo(size: 32),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Align(
                    child: BrandLogo(
                      size: 72,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    widget.role == AuthRole.admin
                        ? 'Welcome Back, Admin'
                        : widget.role == AuthRole.restaurant
                            ? 'Welcome Back, Restaurant'
                            : 'Welcome Back',
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Sign in to continue',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
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
                          const SizedBox(height: 16),
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
                          const SizedBox(height: 24),
                          AppButton(
                            label: 'Sign In',
                            isLoading: authState.isLoading,
                            onPressed: _handleLogin,
                          ),
                          if (widget.role != AuthRole.admin) ...[
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () => context.go(
                                widget.role == AuthRole.restaurant
                                    ? '/register/restaurant'
                                    : '/register/user',
                              ),
                              child: const Text(
                                "Don't have an account? Sign Up",
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
