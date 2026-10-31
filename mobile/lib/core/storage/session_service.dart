import 'dart:async';

import 'package:get/get.dart';

import '../../routes/app_routes.dart';
import 'token_storage.dart';

class SessionService extends GetxService {
  SessionService(this._tokenStorage);

  final TokenStorage _tokenStorage;
  final RxBool isLoggedIn = false.obs;
  final RxBool profileCompleted = false.obs;

  // Where the app should land right now. Used by the splash screen and by
  // the OTP screen so both route the user the same way.
  String get landingRoute {
    if (!isLoggedIn.value) {
      return AppRoutes.auth;
    }
    return profileCompleted.value ? AppRoutes.home : AppRoutes.profileSetup;
  }

  @override
  void onInit() {
    super.onInit();
    unawaited(restore());
  }

  Future<void> restore() async {
    try {
      final accessToken = await _tokenStorage.readAccessToken();
      isLoggedIn.value = accessToken != null && accessToken.isNotEmpty;
      profileCompleted.value =
          isLoggedIn.value && await _tokenStorage.readProfileCompleted();
    } catch (_) {
      isLoggedIn.value = false;
      profileCompleted.value = false;
    }
  }

  Future<String?> readAccessToken() {
    return _tokenStorage.readAccessToken();
  }

  Future<String?> readRefreshToken() {
    return _tokenStorage.readRefreshToken();
  }

  // profileCompleted stays unchanged when null, so a silent token refresh
  // does not overwrite what the user already finished.
  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    bool? profileCompleted,
  }) async {
    await _tokenStorage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    isLoggedIn.value = true;

    if (profileCompleted != null) {
      await markProfileCompleted(profileCompleted);
    }
  }

  Future<void> markProfileCompleted(bool value) async {
    await _tokenStorage.saveProfileCompleted(value);
    profileCompleted.value = value;
  }

  Future<void> clearSession() async {
    try {
      await _tokenStorage.clearTokens();
    } finally {
      isLoggedIn.value = false;
      profileCompleted.value = false;
    }
  }
}
