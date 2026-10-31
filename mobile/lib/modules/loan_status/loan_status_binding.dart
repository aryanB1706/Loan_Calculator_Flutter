import 'package:get/get.dart';

import '../../core/network/api_client.dart';
import '../../data/models/loan_application.dart';
import '../../data/repositories/loan_repository.dart';
import 'loan_status_controller.dart';

class LoanStatusBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoanStatusController>(
      () => LoanStatusController(
        LoanRepository(Get.find<ApiClient>()),
        Get.arguments as LoanApplication,
      ),
    );
  }
}
