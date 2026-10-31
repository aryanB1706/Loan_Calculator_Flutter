import 'package:get/get.dart';

import '../../core/storage/session_service.dart';

class SplashController extends GetxController {
  SplashController(this._session);

  final SessionService _session;

  static const Duration _minimumDisplayTime = Duration(milliseconds: 1500);

  @override
  void onReady() {
    super.onReady();
    _routeBySession();
  }

  Future<void> _routeBySession() async {
    // Run both together so a fast storage read does not make the logo flash.
    await Future.wait([
      _session.restore(),
      Future.delayed(_minimumDisplayTime),
    ]);
    Get.offAllNamed(_session.landingRoute);
  }
}
