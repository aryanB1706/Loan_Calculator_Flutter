import 'package:get/get.dart';

import '../../core/network/api_client.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthController>(
      () => AuthController(AuthRepository(Get.find<ApiClient>())),
    );
  }
}
