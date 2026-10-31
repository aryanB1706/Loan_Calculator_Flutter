import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/loan_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_formatters.dart';
import '../../core/widgets/app_dropdown_field.dart';
import '../../core/widgets/gradient_border_card.dart';
import '../../core/widgets/journey_scaffold.dart';
import 'loan_apply_controller.dart';

class LoanApplyView extends GetView<LoanApplyController> {
  const LoanApplyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => JourneyScaffold(
        title: 'Review application',
        currentStep: 1,
        buttonLabel: 'Submit application',
        isLoading: controller.isSubmitting.value,
        onButtonPressed: controller.submit,
        onBack: Get.back,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Check the details below, choose a purpose and submit.',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 24),
            AppDropdownField<String>(
              label: 'Purpose of Loan*',
              hint: 'Select purpose of loan',
              value: controller.purpose.value,
              errorText: controller.purposeError.value,
              items: [
                for (final purpose in LoanPurposes.options)
                  DropdownMenuItem(value: purpose, child: Text(purpose)),
              ],
              onChanged: controller.setPurpose,
            ),
            const SizedBox(height: 24),
            _buildSummary(),
            _buildErrors(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    final terms = controller.offer.terms;
    final quote = controller.offer.quote;

    return GradientBorderCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          _row('Loan amount', AppFormatters.currency(terms.amount)),
          _row('Tenure', '${terms.tenureMonths} months'),
          _row('Interest rate', '${quote.interestRate}% p.a.'),
          _row('Monthly EMI', AppFormatters.currencyPrecise(quote.emi)),
          _row(
            'Total interest',
            AppFormatters.currencyPrecise(quote.totalInterest),
          ),
          _row(
            'Total payable',
            AppFormatters.currencyPrecise(quote.totalPayable),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: AppTextStyles.body)),
          Text(
            value,
            style: AppTextStyles.title.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrors() {
    final message = controller.errorMessage.value;
    if (message == null) {
      return const SizedBox.shrink();
    }

    final errorStyle = AppTextStyles.body.copyWith(color: AppColors.error);

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: errorStyle),
          for (final reason in controller.ineligibleReasons)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('• $reason', style: AppTextStyles.caption),
            ),
          const SizedBox(height: 12),
          if (controller.hasActiveApplication.value)
            TextButton(
              onPressed: controller.goHome,
              child: const Text('View my application on Home'),
            )
          else if (controller.ineligibleReasons.isNotEmpty)
            TextButton(
              onPressed: controller.changeTerms,
              child: const Text('Change amount or tenure'),
            ),
        ],
      ),
    );
  }
}
