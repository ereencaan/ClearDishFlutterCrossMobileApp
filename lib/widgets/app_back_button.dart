import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A reusable rounded back button that gracefully falls back to a route.
class AppBackButton extends StatelessWidget {
  const AppBackButton({
    super.key,
    this.fallbackRoute,
    this.showLabel = false,
    this.label = 'Back',
  });

  /// Route to navigate to when the router cannot pop.
  final String? fallbackRoute;

  /// Whether to render the text label next to the icon.
  final bool showLabel;

  /// Label text shown when [showLabel] is true.
  final String label;

  @override
  Widget build(BuildContext context) {
    final router = GoRouter.of(context);
    final canPop = router.canPop() || Navigator.of(context).canPop();
    final shouldRender = canPop || fallbackRoute != null;

    if (!shouldRender) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    final icon = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.4),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 18,
          color: colorScheme.primary,
        ),
        onPressed: () => _handleBack(context, router),
        splashRadius: 22,
      ),
    );

    if (!showLabel) {
      return Padding(
        padding: const EdgeInsets.only(left: 8),
        child: icon,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => _handleBack(context, router),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleBack(BuildContext context, GoRouter router) {
    if (router.canPop()) {
      router.pop();
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    if (fallbackRoute != null) {
      router.go(fallbackRoute!);
      return;
    }
    router.go('/home');
  }
}
