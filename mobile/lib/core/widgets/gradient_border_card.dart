import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';
import '../theme/app_colors.dart';

/// White card with the blue-to-mint gradient outline used by the design.
class GradientBorderCard extends StatelessWidget {
  const GradientBorderCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  static const double _borderWidth = 1.5;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(_borderWidth),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryLight, AppColors.mint],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
      ),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(
            AppSizes.radiusLarge - _borderWidth,
          ),
        ),
        child: child,
      ),
    );
  }
}
