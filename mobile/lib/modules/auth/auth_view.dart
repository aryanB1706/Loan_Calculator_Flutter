import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/constants/auth_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/auth_shell.dart';
import '../../core/widgets/india_flag.dart';
import '../../core/widgets/primary_button.dart';
import 'auth_controller.dart';

class AuthView extends GetView<AuthController> {
  const AuthView({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      sheet: Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'Welcome to Credit Sea!',
                style: AppTextStyles.heading,
              ),
            ),
            const SizedBox(height: 24),
            const Text('Mobile Number', style: AppTextStyles.label),
            const SizedBox(height: 8),
            _buildPhoneRow(),
            const SizedBox(height: 16),
            _buildTermsRow(),
            Obx(() => _buildError(controller.errorMessage.value)),
            const SizedBox(height: 16),
            Obx(
              () => PrimaryButton(
                label: 'Request OTP',
                isLoading: controller.isLoading.value,
                onPressed: controller.requestOtp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: AppSizes.fieldHeight,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            border: Border.all(color: AppColors.border),
          ),
          child: const Row(
            children: [
              IndiaFlag(),
              SizedBox(width: 8),
              Text(AuthConstants.countryCode, style: AppTextStyles.bodyLarge),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppTextField(
            controller: controller.phoneController,
            hint: 'Please enter your mobile no.',
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            maxLength: AuthConstants.mobileLength,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: Validators.mobileNumber,
            onChanged: (_) => controller.errorMessage.value = null,
          ),
        ),
      ],
    );
  }

  Widget _buildTermsRow() {
    final linkStyle = AppTextStyles.bodySmall.copyWith(
      decoration: TextDecoration.underline,
      color: AppColors.textSecondary,
    );

    return Row(
      children: [
        Obx(
          () => Checkbox(
            value: controller.termsAccepted.value,
            onChanged: controller.toggleTerms,
            activeColor: AppColors.secondary,
            visualDensity: VisualDensity.compact,
          ),
        ),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: AppTextStyles.caption,
              children: [
                const TextSpan(text: 'By continuing, you agree to our '),
                TextSpan(text: 'privacy policies', style: linkStyle),
                const TextSpan(text: ' and '),
                TextSpan(text: 'Terms & Conditions.', style: linkStyle),
              ],
            ),
          ),
        ),
      ],
    );
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
