import 'package:get/get.dart';

import '../../data/models/loan_application.dart';
import '../../routes/app_routes.dart';

class LoanSuccessController extends GetxController {
  LoanSuccessController(this.application);

  final LoanApplication application;

  // Home stays underneath so back from the status page returns there.
  void trackStatus() {
    Get.offAllNamed(AppRoutes.home);
    Get.toNamed(AppRoutes.loanStatus, arguments: application);
  }

  void goHome() => Get.offAllNamed(AppRoutes.home);
}
