import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The status values the backend uses for a loan application.
class LoanStatus {
  const LoanStatus._();

  static const String submitted = 'submitted';
  static const String underReview = 'under_review';
  static const String approved = 'approved';
  static const String rejected = 'rejected';
  static const String disbursed = 'disbursed';

  static String label(String status) {
    switch (status) {
      case submitted:
        return 'Submitted';
      case underReview:
        return 'Under Review';
      case approved:
        return 'Approved';
      case rejected:
        return 'Rejected';
      case disbursed:
        return 'Disbursed';
      default:
        return status;
    }
  }

  static Color color(String status) {
    switch (status) {
      case approved:
      case disbursed:
        return AppColors.success;
      case rejected:
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }
}
