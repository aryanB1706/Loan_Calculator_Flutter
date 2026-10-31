import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loan_app/core/storage/session_service.dart';
import 'package:loan_app/core/storage/token_storage.dart';

class FakeTokenStorage extends TokenStorage {
  FakeTokenStorage() : super(storage: const FlutterSecureStorage());

  String? accessToken;
  String? refreshToken;

  @override
  Future<String?> readAccessToken() async => accessToken;

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }

  @override
  Future<void> clearTokens() async {
    accessToken = null;
    refreshToken = null;
  }
}

void main() {
  test('isLoggedIn becomes true after saving a session', () async {
    final storage = FakeTokenStorage();
    final session = SessionService(storage);

    await session.saveSession(accessToken: 'access', refreshToken: 'refresh');

    expect(session.isLoggedIn.value, isTrue);
    expect(storage.accessToken, 'access');
    expect(storage.refreshToken, 'refresh');
  });

  test('restore detects an existing access token', () async {
    final storage = FakeTokenStorage()..accessToken = 'existing';
    final session = SessionService(storage);

    await session.restore();

    expect(session.isLoggedIn.value, isTrue);
  });

  test('clearSession removes tokens and updates the login state', () async {
    final storage = FakeTokenStorage()..accessToken = 'existing';
    final session = SessionService(storage);
    await session.restore();

    await session.clearSession();

    expect(session.isLoggedIn.value, isFalse);
    expect(storage.accessToken, isNull);
    expect(storage.refreshToken, isNull);
  });
}
