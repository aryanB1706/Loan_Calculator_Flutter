import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/constants/profile_options.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_formatters.dart';
import '../../core/widgets/app_loader.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/models/credit_score.dart';
import '../../data/models/user_model.dart';
import 'profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: SafeArea(child: Obx(_buildBody)),
    );
  }

  Widget _buildBody() {
    if (controller.isLoading.value) {
      return const AppLoader();
    }

    final user = controller.user.value;
    final creditScore = controller.creditScore.value;

    if (user == null || creditScore == null) {
      return _buildError(controller.errorMessage.value);
    }

    return ListView(
      padding: const EdgeInsets.all(AppSizes.pagePadding),
      children: [
        _CreditScoreCard(creditScore: creditScore),
        const SizedBox(height: 24),
        _DetailsCard(user: user),
        const SizedBox(height: 24),
        PrimaryButton(label: 'Edit details', onPressed: controller.editProfile),
        const SizedBox(height: 16),
        Obx(
          () => OutlinedButton(
            onPressed: controller.isLoggingOut.value ? null : _confirmLogout,
            child: const Text('Log out'),
          ),
        ),
      ],
    );
  }

  Widget _buildError(String? message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message ?? 'Could not load your profile.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: controller.load,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          'You will need to verify your mobile number to sign in again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await controller.logout();
    }
  }
}

class _CreditScoreCard extends StatelessWidget {
  const _CreditScoreCard({required this.creditScore});

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
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final rows = {
      'Name': user.fullName,
      'Mobile': '+91 ${user.phone}',
      'Email': user.email,
      'Gender': ProfileOptions.labelFor(ProfileOptions.genders, user.gender),
      'Date of birth': user.dob == null ? null : AppFormatters.date(user.dob!),
      'PAN': user.pan,
      'Monthly income': user.monthlyIncome == null
          ? null
          : AppFormatters.currency(user.monthlyIncome!),
      'Employment': ProfileOptions.labelFor(
        ProfileOptions.employmentTypes,
        user.employmentType,
      ),
      'City': user.city,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (final entry in rows.entries) _buildRow(entry.key, entry.value),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(label, style: AppTextStyles.caption)),
          Expanded(
            flex: 3,
            child: Text(
              value == null || value.isEmpty ? '-' : value,
              textAlign: TextAlign.end,
              style: AppTextStyles.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

String _capitalize(String value) {
  return value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
}
