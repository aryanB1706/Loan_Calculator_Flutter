import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_formatters.dart';
import '../../core/widgets/app_loader.dart';
import '../../core/widgets/state_message.dart';
import '../../core/widgets/status_chip.dart';
import '../../data/models/loan_application.dart';
import 'applications_controller.dart';

class ApplicationsView extends GetView<ApplicationsController> {
  const ApplicationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Applications')),
      body: SafeArea(child: Obx(_buildBody)),
    );
  }

  Widget _buildBody() {
    if (controller.isLoading.value) {
      return const AppLoader();
    }

    return RefreshIndicator(onRefresh: controller.reload, child: _buildList());
  }

  Widget _buildList() {
    final error = controller.errorMessage.value;

    if (controller.applications.isEmpty) {
      return _buildScrollableMessage(
        error == null ? _buildEmpty() : _buildError(error),
      );
    }

    final items = controller.applications;

    return ListView.separated(
      controller: controller.scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSizes.pagePadding),
      itemCount: items.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, index) {
        return index < items.length ? _buildCard(items[index]) : _buildFooter();
      },
    );
  }

  // Lets pull-to-refresh work even when there is nothing to scroll.
  Widget _buildScrollableMessage(Widget child) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSizes.pagePadding),
      children: [const SizedBox(height: 120), child],
    );
  }

  Widget _buildCard(LoanApplication application) {
    final date = application.createdAt;

    return InkWell(
      borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
      onTap: () => controller.openApplication(application),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '#${application.applicationNumber}',
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.title,
                  ),
                ),
                const SizedBox(width: 8),
                StatusChip.loan(application.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${AppFormatters.currency(application.amount)} for '
              '${application.tenureMonths} months',
              style: AppTextStyles.bodyMedium,
            ),
            if (date != null) ...[
              const SizedBox(height: 4),
              Text(
                'Applied on ${AppFormatters.date(date)}',
                style: AppTextStyles.caption,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Obx(() {
      if (controller.isLoadingMore.value) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: AppLoader(),
        );
      }
      if (controller.loadMoreFailed.value) {
        return TextButton(
          onPressed: controller.loadMore,
          child: const Text('Could not load more. Tap to retry'),
        );
      }
      return const SizedBox.shrink();
    });
  }

  Widget _buildEmpty() {
    return StateMessage(
      icon: Icons.description_outlined,
      title: 'No applications yet',
      message: 'Your loan applications will appear here.',
      actionLabel: 'Apply for a loan',
      onAction: controller.applyForLoan,
    );
  }

  Widget _buildError(String message) {
    return StateMessage.error(
      message: message,
      isOffline: controller.isOffline.value,
      onRetry: controller.retry,
    );
  }
}
