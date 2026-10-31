import 'package:get/get.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_service.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';
import 'profile_setup_controller.dart';

class ProfileSetupBinding extends Bindings {
  @override
  void dependencies() {
    // Arguments hold the current profile when editing, and are empty on first setup.
    final existing = Get.arguments is UserModel
        ? Get.arguments as UserModel
        : null;

    Get.lazyPut<ProfileSetupController>(
      () => ProfileSetupController(
        UserRepository(Get.find<ApiClient>()),
        Get.find<SessionService>(),
        existing,
      ),
    );
  }
}
