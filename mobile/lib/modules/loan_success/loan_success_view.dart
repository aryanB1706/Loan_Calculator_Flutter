import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/journey_result_scaffold.dart';
import 'loan_success_controller.dart';

class LoanSuccessView extends GetView<LoanSuccessController> {
  const LoanSuccessView({super.key});

  @override
  Widget build(BuildContext context) {
    // The form is already submitted, so back goes Home instead of to the form.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          controller.goHome();
        }
      },
      child: JourneyResultScaffold(
        currentStep: 2,
        primaryLabel: 'Track status',
        onPrimary: controller.trackStatus,
        secondaryLabel: 'Back to home',
        onSecondary: controller.goHome,
        content: Column(
          children: [
            const Icon(Icons.check_circle, size: 88, color: AppColors.success),
            const SizedBox(height: 24),
            const Text(
              'Application submitted',
              textAlign: TextAlign.center,
              style: AppTextStyles.heading,
            ),
            const SizedBox(height: 16),
            Text(
              'Loan application no.',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '#${controller.application.applicationNumber}',
              style: AppTextStyles.title.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 16),
            const Text(
              'We are reviewing your application and will notify you about '
              'every update.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body,
            ),
          ],
        ),
      ),
    );
  }
}
