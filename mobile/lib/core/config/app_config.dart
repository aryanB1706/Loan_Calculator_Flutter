import 'package:flutter/foundation.dart';

class AppConfig {
  const AppConfig._();

  static const String appName = 'Loan App';

  // Pass --dart-define=API_BASE_URL=https://<host> (server origin only; the
  // /api prefix is added below). It is required for release builds; the local
  // addresses below are development conveniences for debug builds only.
  static const String _baseUrlOverride = String.fromEnvironment('API_BASE_URL');

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);

  static String get baseUrl {
    if (_baseUrlOverride.trim().isNotEmpty) {
      return _stripTrailingSlash(_baseUrlOverride.trim());
    }

    if (!kDebugMode) {
      throw StateError(
        'API_BASE_URL is not set. Build with --dart-define=API_BASE_URL=<url>.',
      );
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000';
    }

    return 'http://localhost:5000';
  }

  static String get apiBaseUrl => '$baseUrl/api';

  static String _stripTrailingSlash(String value) {
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }
}
