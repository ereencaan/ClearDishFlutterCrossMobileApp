import 'package:flutter/material.dart';

/// BrandLogo shows the ClearDish logo image and wordmark side-by-side.
/// Place assets/branding/logo.png (preferably 1024x1024) in the project.
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
          'assets/branding/logo.png',
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


