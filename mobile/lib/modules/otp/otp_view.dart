import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/auth_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/auth_shell.dart';
import '../../core/widgets/otp_input.dart';
import '../../core/widgets/primary_button.dart';
import 'otp_controller.dart';

class OtpView extends GetView<OtpController> {
  const OtpView({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      initialSlide: 1,
      sheet: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildSentTo(),
          const SizedBox(height: 16),
          Obx(
            () => OtpInput(
              length: AuthConstants.otpLength,
              controller: controller.otpTextController,
              onChanged: controller.onOtpChanged,
              hasError: controller.errorMessage.value != null,
              enabled: !controller.isLoading.value,
            ),
          ),
          _buildDemoHint(),
          Obx(() => _buildError(controller.errorMessage.value)),
          const SizedBox(height: 16),
          Obx(() => _buildResendRow()),
          const SizedBox(height: 16),
          Obx(
            () => PrimaryButton(
              label: 'Verify',
              isLoading: controller.isLoading.value,
              onPressed: controller.verify,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          onPressed: Get.back,
          icon: const Icon(Icons.arrow_back, color: AppColors.textMuted),
        ),
        const Expanded(
          child: Text(
            'Enter OTP',
            textAlign: TextAlign.center,
            style: AppTextStyles.heading,
          ),
        ),
        // Balances the back button so the title stays centered.
        const SizedBox(width: 48),
      ],
    );
  }

  Widget _buildSentTo() {
    return Text.rich(
      TextSpan(
        style: AppTextStyles.bodyLarge,
        children: [
          const TextSpan(text: 'Verify OTP, Sent on '),
          TextSpan(text: controller.displayPhone, style: AppTextStyles.title),
        ],
      ),
    );
  }

  Widget _buildDemoHint() {
    final demoOtp = controller.demoOtp;
    if (demoOtp == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        'Demo mode: use OTP $demoOtp',
        style: AppTextStyles.caption.copyWith(color: AppColors.error),
      ),
    );
  }

  Widget _buildResendRow() {
    if (controller.canResend) {
      return GestureDetector(
        onTap: controller.resend,
        child: Text(
          'Resend OTP',
          style: AppTextStyles.label.copyWith(color: AppColors.primary),
        ),
      );
    }

    return Text(controller.countdownText, style: AppTextStyles.label);
  }

  Widget _buildError(String? message) {
    if (message == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        message,
        style: AppTextStyles.caption.copyWith(color: AppColors.error),
      ),
    );
  }
}
