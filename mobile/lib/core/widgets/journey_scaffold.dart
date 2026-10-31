import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'primary_button.dart';
import 'register_stepper.dart';

/// Page layout of the loan journey: stepper on top, a rounded white sheet with
/// a title and back arrow, and the primary action pinned at the bottom.
class JourneyScaffold extends StatelessWidget {
  const JourneyScaffold({
    super.key,
    required this.title,
    required this.body,
    this.buttonLabel,
    this.onButtonPressed,
    this.onBack,
    this.onRefresh,
    this.isLoading = false,
    this.currentStep = 0,
  });

  final String title;
  final Widget body;
  final String? buttonLabel;
  final VoidCallback? onButtonPressed;
  final VoidCallback? onBack;

  // When set, the body can be pulled down to refresh.
  final Future<void> Function()? onRefresh;
  final bool isLoading;
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: RegisterStepper(currentStep: currentStep),
            ),
            Expanded(child: _buildSheet()),
          ],
        ),
      ),
    );
  }

  Widget _buildSheet() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppColors.sheetShadow,
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTitleRow(),
          Expanded(child: _buildScrollArea()),
          if (buttonLabel != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.pagePadding,
                8,
                AppSizes.pagePadding,
                24,
              ),
              child: PrimaryButton(
                label: buttonLabel!,
                isLoading: isLoading,
                onPressed: onButtonPressed,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScrollArea() {
    final scrollView = SingleChildScrollView(
      physics: onRefresh == null ? null : const AlwaysScrollableScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(
        AppSizes.pagePadding,
        16,
        AppSizes.pagePadding,
        16,
      ),
      child: body,
    );

    return onRefresh == null
        ? scrollView
        : RefreshIndicator(onRefresh: onRefresh!, child: scrollView);
  }

  Widget _buildTitleRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 20, 24, 0),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back))
          else
            const SizedBox(width: 12),
          const SizedBox(width: 4),
          Expanded(child: Text(title, style: AppTextStyles.heading)),
        ],
      ),
    );
  }
}
