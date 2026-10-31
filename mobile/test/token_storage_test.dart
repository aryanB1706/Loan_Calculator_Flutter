import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loan_app/core/storage/token_storage.dart';

class _BrokenStorage extends FlutterSecureStorage {
  const _BrokenStorage();

  static bool wiped = false;

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => throw Exception('OperationError');

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => throw Exception('OperationError');

  @override
  Future<void> deleteAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => wiped = true;
}

void main() {
  test('unreadable stored data is treated as no session and wiped', () async {
    final storage = TokenStorage(storage: const _BrokenStorage());

    expect(await storage.readAccessToken(), isNull);
    expect(await storage.readProfileCompleted(), isFalse);
    expect(_BrokenStorage.wiped, isTrue);
  });

  test(
    'tokens stay usable in memory when storage cannot write or read',
    () async {
      final storage = TokenStorage(storage: const _BrokenStorage());

      await storage.saveTokens(accessToken: 'access', refreshToken: 'refresh');

      expect(await storage.readAccessToken(), 'access');
      expect(await storage.readRefreshToken(), 'refresh');
    },
  );
}
