import 'package:get/get.dart';

import '../../core/network/api_client.dart';
import '../../data/repositories/loan_repository.dart';
import '../../data/repositories/user_repository.dart';
import 'home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    final api = Get.find<ApiClient>();

    Get.lazyPut<HomeController>(
      () => HomeController(UserRepository(api), LoanRepository(api)),
    );
  }
}
