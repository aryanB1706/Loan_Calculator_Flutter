import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_formatters.dart';
import '../../core/widgets/app_loader.dart';
import '../../core/widgets/credit_score_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/state_message.dart';
import '../../core/widgets/status_chip.dart';
import '../../data/models/loan_application.dart';
import 'home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Credit Sea'),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'My profile',
            onPressed: controller.openProfile,
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
      body: SafeArea(child: Obx(_buildBody)),
    );
  }

  Widget _buildBody() {
    if (controller.isLoading.value) {
      return const AppLoader();
    }

    final creditScore = controller.creditScore.value;
    if (creditScore == null) {
      return _buildError();
    }

    return RefreshIndicator(
      onRefresh: controller.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSizes.pagePadding),
        children: [
          Text(
            controller.firstName.isEmpty
                ? 'Hello!'
                : 'Hello, ${controller.firstName}!',
            style: AppTextStyles.heading,
          ),
          const SizedBox(height: 4),
          const Text(
            'Here is your loan summary.',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 24),
          CreditScoreCard(creditScore: creditScore),
          const SizedBox(height: 16),
          _buildApplyCard(),
          const SizedBox(height: 16),
          _buildLatestApplication(controller.latestApplication.value),
        ],
      ),
    );
  }

  Widget _buildApplyCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Need funds quickly?', style: AppTextStyles.title),
          const SizedBox(height: 8),
          const Text(
            'Pick an amount and tenure to see your EMI, then apply in minutes.',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Apply for a loan',
            onPressed: controller.openCalculator,
          ),
        ],
      ),
    );
  }

  Widget _buildLatestApplication(LoanApplication? application) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: application == null
          ? const Text(
              'You have no loan applications yet.',
              style: AppTextStyles.body,
            )
          : _buildApplicationDetails(application),
    );
  }

  Widget _buildApplicationDetails(LoanApplication application) {
    return InkWell(
      onTap: controller.openLatestApplication,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Latest application', style: AppTextStyles.title),
              StatusChip.loan(application.status),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '#${application.applicationNumber}',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 4),
          Text(
            '${AppFormatters.currency(application.amount)} for '
            '${application.tenureMonths} months',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: controller.openApplications,
              child: const Text('View all applications'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return StateMessage.error(
      message:
          controller.errorMessage.value ?? 'Could not load your home screen.',
      isOffline: controller.isOffline.value,
      onRetry: controller.retry,
    );
  }
}
