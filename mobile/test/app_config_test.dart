import 'package:flutter_test/flutter_test.dart';
import 'package:loan_app/core/config/app_config.dart';

void main() {
  test('uses the deployed backend unless API_BASE_URL is given', () {
    expect(AppConfig.baseUrl, 'https://credit-sea-api.onrender.com');
  });

  test('adds the /api prefix to the server origin', () {
    expect(AppConfig.apiBaseUrl, 'https://credit-sea-api.onrender.com/api');
  });

  test('allows a wake-up from the free plan before timing out', () {
    expect(AppConfig.connectTimeout.inSeconds, greaterThanOrEqualTo(30));
    expect(AppConfig.receiveTimeout.inSeconds, greaterThanOrEqualTo(60));
  });
}
