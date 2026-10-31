import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/journey_scaffold.dart';
import '../../core/widgets/status_chip.dart';
import '../../core/widgets/status_timeline.dart';
import '../../data/models/loan_application.dart';
import 'loan_status_controller.dart';
import 'loan_timeline.dart';
import 'repayment_schedule.dart';

// Design: 12_application_status_1.png
class LoanStatusView extends GetView<LoanStatusController> {
  const LoanStatusView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loan = controller.application.value;

      return JourneyScaffold(
        title: 'Application Status',
        currentStep: 2,
        onBack: Get.back,
        onRefresh: controller.reload,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                style: AppTextStyles.bodyLarge,
                children: [
                  const TextSpan(text: 'Loan application no. '),
                  TextSpan(
                    text: '#${loan.applicationNumber}',
                    style: AppTextStyles.title,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            StatusChip.loan(loan.status),
            const SizedBox(height: 24),
            StatusTimeline(steps: buildLoanTimeline(loan)),
            const SizedBox(height: 32),
            _buildStatusMessage(loan),
            _buildRefreshError(),
            if (controller.isDisbursed) ...[
              const SizedBox(height: 32),
              RepaymentSchedule(
                repayments: controller.repayments,
                nextInstallment: controller.nextInstallment,
                isPaying: controller.isPaying.value,
                onPay: controller.payNextInstallment,
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildStatusMessage(LoanApplication loan) {
    final info = describeLoanStatus(loan);

    return Column(
      children: [
        Text(
          info.title,
          textAlign: TextAlign.center,
          style: AppTextStyles.heading,
        ),
        const SizedBox(height: 8),
        Text(
          info.message,
          textAlign: TextAlign.center,
          style: AppTextStyles.body,
        ),
      ],
    );
  }

  Widget _buildRefreshError() {
    final message = controller.errorMessage.value;
    if (message == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text(
        '$message Pull down to try again.',
        textAlign: TextAlign.center,
        style: AppTextStyles.caption.copyWith(color: AppColors.error),
      ),
    );
  }
}
