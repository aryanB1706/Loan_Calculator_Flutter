import 'package:get/get.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_service.dart';
import '../../data/repositories/auth_repository.dart';
import 'otp_arguments.dart';
import 'otp_controller.dart';

class OtpBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OtpController>(
      () => OtpController(
        AuthRepository(Get.find<ApiClient>()),
        Get.find<SessionService>(),
        Get.arguments as OtpArguments,
      ),
    );
  }
}
