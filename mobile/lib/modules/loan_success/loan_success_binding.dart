import 'package:get/get.dart';

import '../../data/models/loan_application.dart';
import 'loan_success_controller.dart';

class LoanSuccessBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoanSuccessController>(
      () => LoanSuccessController(Get.arguments as LoanApplication),
    );
  }
}
