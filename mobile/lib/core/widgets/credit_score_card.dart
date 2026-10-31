import 'package:flutter/material.dart';

import '../../data/models/credit_score.dart';
import '../constants/app_sizes.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class CreditScoreCard extends StatelessWidget {
  const CreditScoreCard({super.key, required this.creditScore});

  final CreditScore creditScore;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Credit score',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.slideSubtitle,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${creditScore.score}',
                style: AppTextStyles.heading.copyWith(
                  color: AppColors.white,
                  fontSize: 32,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.mint,
              borderRadius: BorderRadius.circular(AppSizes.radiusPill),
            ),
            child: Text(
              _capitalize(creditScore.band),
              style: AppTextStyles.label.copyWith(color: AppColors.primaryDark),
            ),
          ),
        ],
      ),
    );
  }

  String _capitalize(String value) {
    return value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
  }
}
