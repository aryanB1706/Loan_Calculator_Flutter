import 'package:flutter/foundation.dart';

class AppConfig {
  const AppConfig._();

  static const String appName = 'Loan App';

  // Pass --dart-define=API_BASE_URL=http://<host>:5000 for physical devices.
  // The value is the server origin only; the /api prefix is added below.
  static const String _baseUrlOverride = String.fromEnvironment('API_BASE_URL');

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);

  static String get baseUrl {
    if (_baseUrlOverride.trim().isNotEmpty) {
      return _stripTrailingSlash(_baseUrlOverride.trim());
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
