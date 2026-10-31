import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/constants/loan_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_formatters.dart';
import '../../core/widgets/dashed_pill.dart';
import '../../core/widgets/gradient_border_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/slider_input_field.dart';
import '../../data/models/loan_quote.dart';
import 'loan_calculator_controller.dart';

class LoanCalculatorView extends GetView<LoanCalculatorController> {
  const LoanCalculatorView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Loan Calculator'), centerTitle: false),
      body: SafeArea(
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(AppSizes.pagePadding),
          children: [
            const Text(
              'Select your preferred loan amount and tenure to see what you '
              'will pay.',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 16),
            Obx(() => _buildRateChip()),
            const SizedBox(height: 32),
            _buildAmountSlider(),
            const SizedBox(height: 32),
            _buildTenureSlider(),
            const SizedBox(height: 32),
            Obx(_buildResultCard),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Check eligibility',
              onPressed: controller.checkEligibility,
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: Get.back, child: const Text('Cancel')),
          ],
        ),
      ),
    );
  }

  Widget _buildRateChip() {
    final rate = controller.quote.value?.interestRate;
    final text = rate == null ? 'Interest Rate -' : 'Interest Rate $rate% p.a.';

    return Align(
      alignment: Alignment.centerLeft,
      child: DashedPill(text: text),
    );
  }

  Widget _buildAmountSlider() {
    return Obx(
      () => SliderInputField(
        label: 'Principal Amount',
        textController: controller.amountText,
        prefixText: '₹ ',
        sliderValue: controller.amount.value.toDouble(),
        min: LoanLimits.minAmount.toDouble(),
        max: LoanLimits.maxAmount.toDouble(),
        divisions: LoanLimits.amountDivisions,
        minLabel: AppFormatters.currency(LoanLimits.minAmount),
        maxLabel: AppFormatters.currency(LoanLimits.maxAmount),
        onSliderChanged: controller.onAmountSliderChanged,
        onTextChanged: controller.onAmountTyped,
        onEditingComplete: controller.finishAmountEditing,
      ),
    );
  }

  Widget _buildTenureSlider() {
    return Obx(
      () => SliderInputField(
        label: 'Tenure',
        textController: controller.tenureText,
        suffixText: ' Months',
        sliderValue: controller.tenureMonths.value.toDouble(),
        min: LoanLimits.minTenureMonths.toDouble(),
        max: LoanLimits.maxTenureMonths.toDouble(),
        divisions: LoanLimits.tenureDivisions,
        minLabel: '${LoanLimits.minTenureMonths} Months',
        maxLabel: '${LoanLimits.maxTenureMonths} Months',
        onSliderChanged: controller.onTenureSliderChanged,
        onTextChanged: controller.onTenureTyped,
        onEditingComplete: controller.finishTenureEditing,
      ),
    );
  }

  Widget _buildResultCard() {
    final quote = controller.quote.value;
    final error = controller.errorMessage.value;

    return GradientBorderCard(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Opacity(
        opacity: controller.isLoading.value ? 0.5 : 1,
        child: error != null && quote == null
            ? Text(
                error,
                style: AppTextStyles.body.copyWith(color: AppColors.error),
              )
            : _buildRows(quote),
      ),
    );
  }

  Widget _buildRows(LoanQuote? quote) {
    return Column(
      children: [
        _row(
          'Principal Amount',
          AppFormatters.currency(controller.amount.value),
        ),
        _row('Monthly EMI', _money(quote?.emi)),
        _row('Total Interest', _money(quote?.totalInterest)),
        _row('Total Payable', _money(quote?.totalPayable)),
      ],
    );
  }

  String _money(num? value) {
    return value == null ? '-' : AppFormatters.currencyPrecise(value);
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: AppTextStyles.bodyLarge)),
          Text(
            value,
            style: AppTextStyles.title.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
