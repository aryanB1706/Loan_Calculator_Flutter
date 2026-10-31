import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/storage_keys.dart';
import '../utils/debug_log.dart';

/// Keeps tokens in secure storage (survives app restarts) and in memory
/// (always available during the current run). The memory copy matters because
/// some platforms, notably the browser, can fail to read back what they wrote;
/// without it every request after login would go out without a token.
class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  String? _accessToken;
  String? _refreshToken;
  bool? _profileCompleted;

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;

    await _write(StorageKeys.accessToken, accessToken);
    await _write(StorageKeys.refreshToken, refreshToken);
  }

  Future<String?> readAccessToken() async {
    return _accessToken ??= await _readOrReset(StorageKeys.accessToken);
  }

  Future<String?> readRefreshToken() async {
    return _refreshToken ??= await _readOrReset(StorageKeys.refreshToken);
  }

  Future<void> saveProfileCompleted(bool value) async {
    _profileCompleted = value;
    await _write(StorageKeys.profileCompleted, value.toString());
  }

  Future<bool> readProfileCompleted() async {
    final cached = _profileCompleted;
    if (cached != null) {
      return cached;
    }

    final value = await _readOrReset(StorageKeys.profileCompleted);
    return value == 'true';
  }

  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    _profileCompleted = null;

    await Future.wait([
      _storage.delete(key: StorageKeys.accessToken),
      _storage.delete(key: StorageKeys.refreshToken),
      _storage.delete(key: StorageKeys.profileCompleted),
    ]);
  }

  // A failed write only costs persistence across restarts: the memory copy
  // keeps the current session working, so it is logged instead of thrown.
  Future<void> _write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (error, stack) {
      logUnexpectedError('TokenStorage.write($key)', error, stack);
    }
  }

  // Stored data can become unreadable (for example the browser's encryption
  // key changed and web storage throws OperationError). Treating that as
  // "no session" lets the user log in again instead of breaking every request.
  Future<String?> _readOrReset(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (error, stack) {
      logUnexpectedError('TokenStorage.read($key)', error, stack);
      try {
        await _storage.deleteAll();
      } catch (_) {
        // Nothing more can be done; the caller still gets "no value".
      }
      return null;
    }
  }
}
