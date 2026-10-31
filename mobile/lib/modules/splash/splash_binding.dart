import 'package:get/get.dart';

import '../../core/storage/session_service.dart';
import 'splash_controller.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    // put (not lazyPut): the view never reads the controller, so a lazy one
    // would never be created and the session check would never run.
    Get.put<SplashController>(SplashController(Get.find<SessionService>()));
  }
}
