import 'package:get/get.dart';

import 'loan_apply_controller.dart';

class LoanApplyBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoanApplyController>(() => LoanApplyController());
  }
}
