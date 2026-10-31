import 'package:get/get.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_service.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/user_repository.dart';
import 'profile_controller.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    final api = Get.find<ApiClient>();

    Get.lazyPut<ProfileController>(
      () => ProfileController(
        UserRepository(api),
        AuthRepository(api),
        Get.find<SessionService>(),
      ),
    );
  }
}
