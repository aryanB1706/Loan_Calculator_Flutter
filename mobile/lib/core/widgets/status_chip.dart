import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';
import '../constants/loan_status.dart';
import '../theme/app_text_styles.dart';

/// Small coloured pill used for loan and installment statuses.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.color});

  factory StatusChip.loan(String status) {
    return StatusChip(
      label: LoanStatus.label(status),
      color: LoanStatus.color(status),
    );
  }

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
      ),
      child: Text(label, style: AppTextStyles.bodySmall.copyWith(color: color)),
    );
  }
}
