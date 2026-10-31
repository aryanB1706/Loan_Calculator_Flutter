import 'package:flutter_test/flutter_test.dart';
import 'package:loan_app/core/network/api_response.dart';

void main() {
  test('parses the backend success envelope', () {
    final response = ApiResponse<Map<String, dynamic>>.fromJson({
      'success': true,
      'message': 'Loan fetched',
      'data': {'id': 'loan-1'},
    }, dataParser: (data) => Map<String, dynamic>.from(data as Map));

    expect(response.success, isTrue);
    expect(response.message, 'Loan fetched');
    expect(response.data?['id'], 'loan-1');
  });

  test('accepts responses without data', () {
    final response = ApiResponse<Object?>.fromJson({
      'success': true,
      'message': 'Logged out',
    });

    expect(response.success, isTrue);
    expect(response.message, 'Logged out');
    expect(response.data, isNull);
  });
}
