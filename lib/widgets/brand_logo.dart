import 'package:flutter/material.dart';

/// BrandLogo shows the ClearDish icon (textless) and optional wordmark.
/// Uses assets/branding/app_icon.png (icon only) everywhere for consistency with launcher and Play Store.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 42, this.showText = true});
  final double size;
  final bool showText;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/branding/app_icon.png',
          height: size,
        ),
        if (showText) ...[
          const SizedBox(width: 12),
          Text(
            'ClearDish',
            style: TextStyle(
              fontSize: size * 0.9,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ],
    );
  }
}
