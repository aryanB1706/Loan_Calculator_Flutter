import 'package:get/get.dart';

import '../../core/network/api_exception.dart';
import '../../core/utils/debug_log.dart';
import '../../core/utils/navigation.dart';
import '../../data/models/loan_offer.dart';
import '../../data/repositories/loan_repository.dart';
import '../../routes/app_routes.dart';

/// Review step: the user picks a purpose and submits the application.
class LoanApplyController extends GetxController {
  LoanApplyController(this._repository, this.offer);

  final LoanRepository _repository;
  final LoanOffer offer;

  final Rxn<String> purpose = Rxn<String>();
  final RxnString purposeError = RxnString();
  final RxBool isSubmitting = false.obs;
  final RxnString errorMessage = RxnString();

  // Reasons the backend gave when it rejected the application as ineligible.
  final RxList<String> ineligibleReasons = <String>[].obs;

  // True when the user already has an application that is still being processed.
  final RxBool hasActiveApplication = false.obs;

  void setPurpose(String? value) {
    purpose.value = value;
    purposeError.value = null;
  }

  Future<void> submit() async {
    if (isSubmitting.value) {
      return;
    }
    if (purpose.value == null) {
      purposeError.value = 'Please select the purpose of the loan';
      return;
    }

    isSubmitting.value = true;
    _clearErrors();

    try {
      final application = await _repository.apply(
        offer.terms,
        purpose: purpose.value!,
      );
      Get.offNamed(AppRoutes.loanSuccess, arguments: application);
    } on ApiException catch (error) {
      _handleApiError(error);
    } catch (error, stack) {
      logUnexpectedError('apply.submit', error, stack);
      errorMessage.value = 'Something went wrong. Please try again.';
    } finally {
      isSubmitting.value = false;
    }
  }

  void goHome() => popUntilHome();

  void changeTerms() {
    Get.until((route) => route.settings.name == AppRoutes.loanCalculator);
  }

  void _handleApiError(ApiException error) {
    if (error.messagesFor('profile').isNotEmpty) {
      // The backend treats the profile as incomplete: send the user to finish it.
      Get.offAllNamed(AppRoutes.profileSetup);
      Get.snackbar('Complete your profile', error.message);
      return;
    }

    final reasons = error.messagesFor('eligibility');
    if (reasons.isNotEmpty) {
      ineligibleReasons.assignAll(reasons);
    }

    hasActiveApplication.value = error.statusCode == 409;
    errorMessage.value = error.message;
  }

  void _clearErrors() {
    errorMessage.value = null;
    ineligibleReasons.clear();
    hasActiveApplication.value = false;
  }
}
