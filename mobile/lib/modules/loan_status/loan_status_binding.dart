import 'package:get/get.dart';

import 'loan_status_controller.dart';

class LoanStatusBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoanStatusController>(() => LoanStatusController());
  }
}
