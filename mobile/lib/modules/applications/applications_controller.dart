import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../core/network/api_exception.dart';
import '../../core/utils/debug_log.dart';
import '../../data/models/loan_application.dart';
import '../../data/models/loan_page.dart';
import '../../data/repositories/loan_repository.dart';
import '../../routes/app_routes.dart';

/// "My Applications": newest first, loaded one page at a time while scrolling.
class ApplicationsController extends GetxController {
  ApplicationsController(this._repository);

  final LoanRepository _repository;

  static const int _pageSize = 10;
  static const double _loadMoreDistance = 200;

  final scrollController = ScrollController();
  final RxList<LoanApplication> applications = <LoanApplication>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool loadMoreFailed = false.obs;
  final RxnString errorMessage = RxnString();

  int _page = 0;
  bool _hasMore = true;

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_onScroll);
    reload();
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  // Starts again from page 1; used on open, on pull-to-refresh and on retry.
  Future<void> reload() async {
    errorMessage.value = null;

    try {
      final result = await _fetch(1);
      applications.assignAll(result.applications);
      _page = result.page;
      _hasMore = result.hasMore;
    } on ApiException catch (error) {
      errorMessage.value = error.message;
    } catch (error, stack) {
      logUnexpectedError('applications.reload', error, stack);
      errorMessage.value = 'Something went wrong. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore || isLoadingMore.value || isLoading.value) {
      return;
    }

    isLoadingMore.value = true;
    loadMoreFailed.value = false;

    try {
      final result = await _fetch(_page + 1);
      applications.addAll(result.applications);
      _page = result.page;
      _hasMore = result.hasMore;
    } catch (error, stack) {
      logUnexpectedError('applications.loadMore', error, stack);
      loadMoreFailed.value = true;
    } finally {
      isLoadingMore.value = false;
    }
  }

  // The details page can change a status, so the list refreshes on return.
  Future<void> openApplication(LoanApplication application) async {
    await Get.toNamed(AppRoutes.loanStatus, arguments: application);
    await reload();
  }

  void applyForLoan() => Get.toNamed(AppRoutes.loanCalculator);

  Future<LoanPage> _fetch(int page) {
    return _repository.listApplications(page: page, limit: _pageSize);
  }

  void _onScroll() {
    final position = scrollController.position;
    if (position.extentAfter < _loadMoreDistance) {
      loadMore();
    }
  }
}
