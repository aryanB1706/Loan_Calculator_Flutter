import 'package:get/get.dart';

import '../../core/network/api_client.dart';
import '../../data/models/loan_terms.dart';
import '../../data/repositories/loan_repository.dart';
import 'loan_eligibility_controller.dart';

class LoanEligibilityBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoanEligibilityController>(
      () => LoanEligibilityController(
        LoanRepository(Get.find<ApiClient>()),
        Get.arguments as LoanTerms,
      ),
    );
  }
}
