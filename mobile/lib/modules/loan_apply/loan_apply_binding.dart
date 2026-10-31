import 'package:get/get.dart';

import '../../core/network/api_client.dart';
import '../../data/models/loan_offer.dart';
import '../../data/repositories/loan_repository.dart';
import 'loan_apply_controller.dart';

class LoanApplyBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoanApplyController>(
      () => LoanApplyController(
        LoanRepository(Get.find<ApiClient>()),
        Get.arguments as LoanOffer,
      ),
    );
  }
}
