import 'dart:async';

import 'package:get/get.dart';

import 'token_storage.dart';

class SessionService extends GetxService {
  SessionService(this._tokenStorage);

  final TokenStorage _tokenStorage;
  final RxBool isLoggedIn = false.obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(restore());
  }

  Future<void> restore() async {
    try {
      final accessToken = await _tokenStorage.readAccessToken();
      isLoggedIn.value = accessToken != null && accessToken.isNotEmpty;
    } catch (_) {
      isLoggedIn.value = false;
    }
  }

  Future<String?> readAccessToken() {
    return _tokenStorage.readAccessToken();
  }

  Future<String?> readRefreshToken() {
    return _tokenStorage.readRefreshToken();
  }

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _tokenStorage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    isLoggedIn.value = true;
  }

  Future<void> clearSession() async {
    try {
      await _tokenStorage.clearTokens();
    } finally {
      isLoggedIn.value = false;
    }
  }
}
