import 'package:get/get.dart';

import '../../core/network/api_exception.dart';
import '../../core/utils/debug_log.dart';
import '../../core/utils/navigation.dart';
import '../../data/models/eligibility_result.dart';
import '../../data/models/loan_offer.dart';
import '../../data/models/loan_quote.dart';
import '../../data/models/loan_terms.dart';
import '../../data/repositories/loan_repository.dart';
import '../../routes/app_routes.dart';

/// Asks the backend whether the chosen terms are allowed, and fetches the quote
/// so the offer screen can show the EMI and total.
class LoanEligibilityController extends GetxController {
  LoanEligibilityController(this._repository, this.terms);

  final LoanRepository _repository;
  final LoanTerms terms;

  final Rxn<EligibilityResult> result = Rxn<EligibilityResult>();
  final Rxn<LoanQuote> quote = Rxn<LoanQuote>();
  final RxBool isLoading = true.obs;
  final RxnString errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      final results = await Future.wait([
        _repository.checkEligibility(terms),
        _repository.calculate(
          amount: terms.amount,
          tenureMonths: terms.tenureMonths,
        ),
      ]);
      result.value = results[0] as EligibilityResult;
      quote.value = results[1] as LoanQuote;
    } on ApiException catch (error) {
      errorMessage.value = error.message;
    } catch (error, stack) {
      logUnexpectedError('eligibility.load', error, stack);
      errorMessage.value = 'Something went wrong. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  void acceptOffer() {
    Get.toNamed(
      AppRoutes.loanApply,
      arguments: LoanOffer(terms: terms, quote: quote.value!),
    );
  }

  void changeTerms() => Get.back();

  void goHome() => popUntilHome();
}
