import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_formatters.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/status_chip.dart';
import '../../data/models/repayment.dart';

/// Installment list shown after disbursement, with a Pay button on the next one.
class RepaymentSchedule extends StatelessWidget {
  const RepaymentSchedule({
    super.key,
    required this.repayments,
    required this.nextInstallment,
    required this.isPaying,
    required this.onPay,
  });

  final List<Repayment> repayments;
  final Repayment? nextInstallment;
  final bool isPaying;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Repayment schedule', style: AppTextStyles.title),
        const SizedBox(height: 12),
        if (repayments.isEmpty)
          const Text(
            'Your schedule is being prepared.',
            style: AppTextStyles.caption,
          )
        else
          for (final repayment in repayments) _buildRow(repayment),
        if (nextInstallment != null) ...[
          const SizedBox(height: 16),
          PrimaryButton(
            label:
                'Pay ${AppFormatters.currencyPrecise(nextInstallment!.amount)}',
            isLoading: isPaying,
            onPressed: onPay,
          ),
          const SizedBox(height: 8),
          const Text(
            'Demo payment: no real money is moved.',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption,
          ),
        ],
      ],
    );
  }

  Widget _buildRow(Repayment repayment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Installment ${repayment.installmentNumber}',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  'Due ${AppFormatters.date(repayment.dueDate)} · '
                  '${AppFormatters.currencyPrecise(repayment.amount)}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          _statusChip(repayment),
        ],
      ),
    );
  }

  Widget _statusChip(Repayment repayment) {
    switch (repayment.status) {
      case 'paid':
        return const StatusChip(label: 'Paid', color: AppColors.success);
      case 'late':
        return const StatusChip(label: 'Paid late', color: AppColors.error);
      default:
        return const StatusChip(
          label: 'Pending',
          color: AppColors.textSecondary,
        );
    }
  }
}
