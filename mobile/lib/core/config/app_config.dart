class AppConfig {
  const AppConfig._();

  static const String appName = 'Loan App';

  // The deployed backend (Render). It is a public address, not a secret.
  static const String _defaultBaseUrl = 'https://credit-sea-api.onrender.com';

  // To use another backend (a local one, for example) pass
  //   --dart-define=API_BASE_URL=http://10.0.2.2:5000
  // The value is the server origin only; the /api prefix is added below.
  static const String _baseUrlOverride = String.fromEnvironment('API_BASE_URL');

  // The free Render plan sleeps when idle, and waking it takes up to a minute,
  // so the first request is allowed to take longer than later ones would.
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);

  static String get baseUrl {
    final override = _baseUrlOverride.trim();
    return _stripTrailingSlash(override.isEmpty ? _defaultBaseUrl : override);
  }

  static String get apiBaseUrl => '$baseUrl/api';

  static String _stripTrailingSlash(String value) {
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }
}
