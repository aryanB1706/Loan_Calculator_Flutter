import 'package:get/get.dart';

import '../../core/constants/loan_status.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/app_formatters.dart';
import '../../core/utils/debug_log.dart';
import '../../data/models/loan_application.dart';
import '../../data/models/repayment.dart';
import '../../data/repositories/loan_repository.dart';

/// Shows one application with its timeline and, once disbursed, its repayments.
class LoanStatusController extends GetxController {
  LoanStatusController(this._repository, LoanApplication initial)
    : application = initial.obs;

  final LoanRepository _repository;

  final Rx<LoanApplication> application;
  final RxList<Repayment> repayments = <Repayment>[].obs;
  final RxBool isRefreshing = true.obs;
  final RxBool isPaying = false.obs;
  final RxnString errorMessage = RxnString();

  bool get isDisbursed => application.value.status == LoanStatus.disbursed;

  // The earliest unpaid installment is the only one the user can pay now.
  Repayment? get nextInstallment {
    for (final repayment in repayments) {
      if (repayment.isPending) {
        return repayment;
      }
    }
    return null;
  }

  @override
  void onInit() {
    super.onInit();
    reload();
  }

  // Public so a push notification can trigger it later.
  Future<void> reload() async {
    errorMessage.value = null;

    try {
      application.value = await _repository.getApplication(
        application.value.id,
      );
      if (isDisbursed) {
        repayments.assignAll(
          await _repository.repayments(application.value.id),
        );
      }
    } on ApiException catch (error) {
      errorMessage.value = error.message;
    } catch (error, stack) {
      logUnexpectedError('status.reload', error, stack);
      errorMessage.value = 'Something went wrong. Please try again.';
    } finally {
      isRefreshing.value = false;
    }
  }

  Future<void> payNextInstallment() async {
    final installment = nextInstallment;
    if (installment == null || isPaying.value) {
      return;
    }

    isPaying.value = true;

    try {
      final result = await _repository.payInstallment(
        application.value.id,
        installment.installmentNumber,
      );
      _replaceRepayment(result.repayment);
      Get.snackbar(
        'Payment successful',
        'Credit score is now ${result.creditScore.score} '
            '(${result.creditScore.band}).',
      );
    } on ApiException catch (error) {
      Get.snackbar('Payment failed', error.message);
    } catch (error, stack) {
      logUnexpectedError('status.pay', error, stack);
      Get.snackbar('Payment failed', 'Something went wrong. Please try again.');
    } finally {
      isPaying.value = false;
    }
  }

  String formatDue(Repayment repayment) =>
      AppFormatters.date(repayment.dueDate);

  void _replaceRepayment(Repayment updated) {
    final index = repayments.indexWhere(
      (item) => item.installmentNumber == updated.installmentNumber,
    );
    if (index != -1) {
      repayments[index] = updated;
    }
  }
}
