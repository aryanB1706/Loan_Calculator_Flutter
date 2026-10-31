import 'package:get/get.dart';

import '../../core/network/api_client.dart';
import '../../data/repositories/loan_repository.dart';
import 'loan_calculator_controller.dart';

class LoanCalculatorBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoanCalculatorController>(
      () => LoanCalculatorController(LoanRepository(Get.find<ApiClient>())),
    );
  }
}
