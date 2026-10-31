import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/constants/profile_options.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_dropdown_field.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/journey_scaffold.dart';
import 'profile_setup_controller.dart';

class ProfileSetupView extends GetView<ProfileSetupController> {
  const ProfileSetupView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final step = controller.step.value;

      return JourneyScaffold(
        title: ProfileSetupController.stepTitles[step],
        buttonLabel: controller.isLastStep ? 'Submit' : 'Continue',
        isLoading: controller.isSaving.value,
        onButtonPressed: controller.next,
        onBack: controller.canGoBack ? controller.goBack : null,
        body: Form(
          key: controller.stepFormKeys[step],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [_buildStep(context, step), _buildGeneralError()],
          ),
        ),
      );
    });
  }

  Widget _buildStep(BuildContext context, int step) {
    switch (step) {
      case 0:
        return _buildPersonalStep(context);
      case 1:
        return _buildEmailStep();
      case 2:
        return _buildPanStep();
      default:
        return _buildEmploymentStep();
    }
  }

  Widget _buildPersonalStep(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppTextField(
                controller: controller.firstName,
                label: 'First Name*',
                hint: 'Your first name',
                textCapitalization: TextCapitalization.words,
                validator: (v) => Validators.name(v, label: 'first name'),
                onChanged: (_) => controller.clearServerError('fullName'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AppTextField(
                controller: controller.lastName,
                label: 'Last Name*',
                hint: 'Your last name',
                textCapitalization: TextCapitalization.words,
                validator: (v) => Validators.name(v, label: 'last name'),
                onChanged: (_) => controller.clearServerError('fullName'),
              ),
            ),
          ],
        ),
        _serverError('fullName'),
        const SizedBox(height: 24),
        Obx(
          () => AppDropdownField<String>(
            label: 'Gender*',
            hint: 'Select your gender',
            value: controller.gender.value,
            errorText: controller.serverErrors['gender'],
            items: _toItems(ProfileOptions.genders),
            onChanged: controller.setGender,
            validator: (v) => Validators.required(v, label: 'gender'),
          ),
        ),
        const SizedBox(height: 24),
        Obx(
          () => AppTextField(
            controller: controller.dobText,
            label: 'Date of Birth*',
            hint: 'DD - MM - YYYY',
            readOnly: true,
            errorText: controller.serverErrors['dob'],
            suffix: const Icon(Icons.calendar_month_outlined),
            onTap: () => _pickDob(context),
            validator: (_) => Validators.dateOfBirth(controller.dob.value),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailStep() {
    return Column(
      children: [
        const SizedBox(height: 16),
        Center(
          child: Image.asset(
            'assets/images/email_illustration.png',
            height: 200,
          ),
        ),
        const SizedBox(height: 32),
        Obx(
          () => AppTextField(
            controller: controller.email,
            label: 'Email ID*',
            hint: 'Enter your email ID',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            errorText: controller.serverErrors['email'],
            validator: Validators.email,
            onChanged: (_) => controller.clearServerError('email'),
          ),
        ),
      ],
    );
  }

  Widget _buildPanStep() {
    return Column(
      children: [
        Center(
          child: Image.asset('assets/images/pan_illustration.png', height: 190),
        ),
        const SizedBox(height: 24),
        Obx(
          () => AppTextField(
            controller: controller.pan,
            label: 'Enter Your PAN Number*',
            hint: 'e.g., ABCDE1234F',
            maxLength: 10,
            textInputAction: TextInputAction.done,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]')),
              _UpperCaseFormatter(),
            ],
            errorText: controller.serverErrors['pan'],
            validator: Validators.pan,
            onChanged: (_) => controller.clearServerError('pan'),
          ),
        ),
      ],
    );
  }

  Widget _buildEmploymentStep() {
    return Column(
      children: [
        Obx(
          () => AppTextField(
            controller: controller.monthlyIncome,
            label: 'Monthly Income*',
            hint: 'Enter your monthly income',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            errorText: controller.serverErrors['monthlyIncome'],
            validator: Validators.monthlyIncome,
            onChanged: (_) => controller.clearServerError('monthlyIncome'),
          ),
        ),
        const SizedBox(height: 24),
        Obx(
          () => AppDropdownField<String>(
            label: 'Employment Type*',
            hint: 'Select',
            value: controller.employmentType.value,
            errorText: controller.serverErrors['employmentType'],
            items: _toItems(ProfileOptions.employmentTypes),
            onChanged: controller.setEmploymentType,
            validator: (v) => Validators.required(v, label: 'employment type'),
          ),
        ),
        const SizedBox(height: 24),
        Obx(
          () => AppTextField(
            controller: controller.city,
            label: 'City*',
            hint: 'Enter your city',
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            errorText: controller.serverErrors['city'],
            validator: Validators.city,
            onChanged: (_) => controller.clearServerError('city'),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDob(BuildContext context) async {
    final latest = controller.latestBirthDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: controller.dob.value ?? latest,
      firstDate: DateTime(1900),
      lastDate: latest,
    );

    if (picked != null) {
      controller.setDob(picked);
    }
  }

  List<DropdownMenuItem<String>> _toItems(List<ProfileOption> options) {
    return [
      for (final option in options)
        DropdownMenuItem(value: option.value, child: Text(option.label)),
    ];
  }

  Widget _serverError(String field) {
    return Obx(() {
      final message = controller.serverErrors[field];
      if (message == null) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          message,
          style: AppTextStyles.caption.copyWith(color: AppColors.error),
        ),
      );
    });
  }

  Widget _buildGeneralError() {
    return Obx(() {
      final message = controller.generalError.value;
      if (message == null) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Text(
          message,
          style: AppTextStyles.caption.copyWith(color: AppColors.error),
        ),
      );
    });
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
