import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'primary_button.dart';

/// Centred icon + message + optional button. One look for every empty, error
/// and no-internet state so screens do not each invent their own.
class StateMessage extends StatelessWidget {
  const StateMessage({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  /// Failure state. [isOffline] switches to the no-internet icon and title.
  factory StateMessage.error({
    Key? key,
    required String message,
    required VoidCallback onRetry,
    bool isOffline = false,
  }) {
    return StateMessage(
      key: key,
      icon: isOffline ? Icons.wifi_off_rounded : Icons.error_outline,
      title: isOffline ? 'No internet connection' : 'Something went wrong',
      message: message,
      actionLabel: 'Try again',
      onAction: onRetry,
    );
  }

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.heading,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: AppTextStyles.body,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              PrimaryButton(label: actionLabel!, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}
