import 'package:get/get.dart';

import '../core/network/api_client.dart';
import '../core/storage/session_service.dart';
import '../core/storage/token_storage.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<TokenStorage>(TokenStorage(), permanent: true);
    Get.put<SessionService>(
      SessionService(Get.find<TokenStorage>()),
      permanent: true,
    );
    Get.put<ApiClient>(ApiClient(Get.find<SessionService>()), permanent: true);
  }
}
