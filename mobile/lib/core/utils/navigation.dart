import 'package:get/get.dart';

import '../../routes/app_routes.dart';

/// Returns to the Home page that is already in the stack.
///
/// Opening Home again with offAllNamed would build a second Home while the old
/// one is removed, and GetX then deletes the controller the new page needs.
void popUntilHome() {
  Get.until((route) => route.settings.name == AppRoutes.home);
}
