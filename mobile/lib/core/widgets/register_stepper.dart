import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Register -> Offer -> Approval progress shown at the top of the loan journey.
class RegisterStepper extends StatelessWidget {
  const RegisterStepper({super.key, this.currentStep = 0});

  static const List<String> _labels = ['Register', 'Offer', 'Approval'];

  // Zero based: 0 = Register, 1 = Offer, 2 = Approval.
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 0; i < _labels.length; i++)
          Flexible(child: _buildStep(i, isActive: i == currentStep)),
      ],
    );
  }

  Widget _buildStep(int index, {required bool isActive}) {
    final color = isActive ? AppColors.primary : AppColors.textSecondary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppColors.primary : AppColors.divider,
          ),
          child: Text(
            '${index + 1}',
            style: AppTextStyles.bodySmall.copyWith(
              color: isActive ? AppColors.white : AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            _labels[index],
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMedium.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
