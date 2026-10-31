import 'package:get/get.dart';

import '../../core/network/api_client.dart';
import '../../data/repositories/loan_repository.dart';
import 'applications_controller.dart';

class ApplicationsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ApplicationsController>(
      () => ApplicationsController(LoanRepository(Get.find<ApiClient>())),
    );
  }
}
