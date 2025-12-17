import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cleardish/widgets/brand_logo.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Stack(
        children: [
          // Animated soft gradient background
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value;
              final c1 = Color.lerp(
                const Color(0xFFE9F8EF),
                const Color(0xFFDCFCE7),
                t,
              )!;
              final c2 = Color.lerp(
                const Color(0xFFCFF3DA),
                const Color(0xFFBBF7D0),
                1 - t,
              )!;
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [c1, c2],
                  ),
                ),
              );
            },
          ),
          // Decorative circles
          Positioned(
            top: -60,
            left: -40,
            child: _blob(colorScheme.primary.withOpacity(0.12), 180),
          ),
          Positioned(
            bottom: -80,
            right: -40,
            child: _blob(colorScheme.secondary.withOpacity(0.12), 220),
          ),
          // Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Align(
                        alignment: Alignment.center,
                        child: BrandLogo(
                          size: 96,
                          showText: false,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => context.go('/login/admin'),
                          child: const Text('Admin sign in'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Healthy choices, with confidence.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                      const SizedBox(height: 32),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth > 720;
                          final double cardWidth =
                              isWide ? 320 : (constraints.maxWidth - 48);
                          final children = [
                            _AnimatedRoleCard(
                              delayMs: 0,
                              child: _RoleCard(
                                title: 'I am a User',
                                subtitle:
                                    'Discover restaurants and order safely',
                                icon: Icons.person,
                                primaryActionText: 'Sign In',
                                secondaryActionText: 'Create Account',
                                onPrimary: () => context.go('/login/user'),
                                onSecondary: () =>
                                    context.go('/register/user'),
                                width: cardWidth,
                              ),
                            ),
                            _AnimatedRoleCard(
                              delayMs: 120,
                              child: _RoleCard(
                                title: 'I am a Restaurant Owner',
                                subtitle:
                                    'Manage your menu, badges and promotions',
                                icon: Icons.storefront,
                                primaryActionText: 'Sign In',
                                secondaryActionText: 'Create Account',
                                onPrimary: () =>
                                    context.go('/login/restaurant'),
                                onSecondary: () =>
                                    context.go('/register/restaurant'),
                                width: cardWidth,
                              ),
                            ),
                          ];
                          return isWide
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    children[0],
                                    const SizedBox(width: 24),
                                    children[1],
                                  ],
                                )
                              : Column(
                                  children: [
                                    children[0],
                                    const SizedBox(height: 24),
                                    children[1],
                                  ],
                                );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blob(Color color, double size) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final s = size * (0.95 + (_controller.value * 0.1));
        return Container(
          width: s,
          height: s,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.primaryActionText,
    this.secondaryActionText,
    required this.onPrimary,
    this.onSecondary,
    this.width = 340,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String primaryActionText;
  final String? secondaryActionText;
  final VoidCallback onPrimary;
  final VoidCallback? onSecondary;
  final double width;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 2,
      color: Colors.black.withOpacity(0.88),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: colorScheme.primary.withOpacity(0.1),
              child: Icon(icon, color: colorScheme.primary, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onPrimary,
              child: Text(primaryActionText),
            ),
            const SizedBox(height: 8),
            if (secondaryActionText != null && onSecondary != null)
              OutlinedButton(
                onPressed: onSecondary,
                child: Text(secondaryActionText!),
              ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedRoleCard extends StatefulWidget {
  const _AnimatedRoleCard({required this.child, this.delayMs = 0});
  final Widget child;
  final int delayMs;

  @override
  State<_AnimatedRoleCard> createState() => _AnimatedRoleCardState();
}

class _AnimatedRoleCardState extends State<_AnimatedRoleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _opacity = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _offset = Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(
      CurvedAnimation(parent: _c, curve: Curves.easeOutCubic),
    );
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}
