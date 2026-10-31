import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_formatters.dart';
import '../../core/widgets/app_loader.dart';
import '../../core/widgets/journey_result_scaffold.dart';
import '../../data/models/eligibility_result.dart';
import 'loan_eligibility_controller.dart';

class LoanEligibilityView extends GetView<LoanEligibilityController> {
  const LoanEligibilityView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Scaffold(
          body: AppLoader(message: 'Checking your eligibility...'),
        );
      }

      final result = controller.result.value;
      if (result == null) {
        return _buildError(controller.errorMessage.value);
      }

      return result.eligible ? _buildOffer() : _buildNotEligible(result);
    });
  }

  // Design: 11_offer.png
  Widget _buildOffer() {
    final terms = controller.terms;
    final quote = controller.quote.value!;
    final bold = AppTextStyles.title.copyWith(fontSize: 18);
    final normal = AppTextStyles.bodyLarge.copyWith(fontSize: 18, height: 1.5);

    return JourneyResultScaffold(
      currentStep: 1,
      primaryLabel: 'Accept Offer',
      onPrimary: controller.acceptOffer,
      secondaryLabel: 'Change terms',
      onSecondary: controller.changeTerms,
      content: Column(
        children: [
          const Text('Our Offerings', style: AppTextStyles.heading),
          const SizedBox(height: 48),
          Image.asset('assets/images/offer_coin.png', height: 96),
          const SizedBox(height: 48),
          Text.rich(
            textAlign: TextAlign.center,
            TextSpan(
              style: normal,
              children: [
                TextSpan(
                  text: 'Congratulations! ',
                  style: normal.copyWith(color: AppColors.success),
                ),
                const TextSpan(text: 'We can offer you '),
                TextSpan(
                  text: AppFormatters.currency(terms.amount),
                  style: bold,
                ),
                const TextSpan(text: ' for '),
                TextSpan(text: '${terms.tenureMonths} months', style: bold),
                const TextSpan(text: ', with an EMI of '),
                TextSpan(
                  text: AppFormatters.currencyPrecise(quote.emi),
                  style: bold,
                ),
                const TextSpan(text: ' and a total payable amount of '),
                TextSpan(
                  text: AppFormatters.currencyPrecise(quote.totalPayable),
                  style: bold,
                ),
                const TextSpan(text: '.'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'You are eligible for up to '
            '${AppFormatters.currency(controller.result.value!.maxEligibleAmount)}.',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }

  Widget _buildNotEligible(EligibilityResult result) {
    return JourneyResultScaffold(
      currentStep: 1,
      primaryLabel: 'Change terms',
      onPrimary: controller.changeTerms,
      secondaryLabel: 'Back to home',
      onSecondary: controller.goHome,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Icon(Icons.info_outline, size: 64, color: AppColors.error),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'You are not eligible for this loan',
              textAlign: TextAlign.center,
              style: AppTextStyles.heading,
            ),
          ),
          const SizedBox(height: 24),
          for (final reason in result.reasons) _buildReason(reason),
          if (result.maxEligibleAmount > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Based on your income you can borrow up to '
              '${AppFormatters.currency(result.maxEligibleAmount)}.',
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReason(String reason) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2, right: 8),
            child: Icon(Icons.close, size: 18, color: AppColors.error),
          ),
          Expanded(child: Text(reason, style: AppTextStyles.body)),
        ],
      ),
    );
  }

  Widget _buildError(String? message) {
    return JourneyResultScaffold(
      currentStep: 1,
      primaryLabel: 'Try again',
      onPrimary: controller.load,
      secondaryLabel: 'Back',
      onSecondary: controller.changeTerms,
      content: Text(
        message ?? 'Could not check your eligibility.',
        textAlign: TextAlign.center,
        style: AppTextStyles.body,
      ),
    );
  }
}
