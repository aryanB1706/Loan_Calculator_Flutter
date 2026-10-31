import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';
import '../theme/app_colors.dart';
import 'primary_button.dart';
import 'register_stepper.dart';

/// Layout for result-style pages of the loan journey: stepper on top, content
/// centred in the middle, and one or two buttons pinned at the bottom.
class JourneyResultScaffold extends StatelessWidget {
  const JourneyResultScaffold({
    super.key,
    required this.currentStep,
    required this.content,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.isLoading = false,
  });

  final int currentStep;
  final Widget content;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: RegisterStepper(currentStep: currentStep),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.pagePadding),
                child: Center(child: content),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.pagePadding,
                0,
                AppSizes.pagePadding,
                24,
              ),
              child: Column(
                children: [
                  PrimaryButton(
                    label: primaryLabel,
                    isLoading: isLoading,
                    onPressed: onPrimary,
                  ),
                  if (secondaryLabel != null) ...[
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: onSecondary,
                      child: Text(secondaryLabel!),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
