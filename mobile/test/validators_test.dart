import 'package:flutter_test/flutter_test.dart';
import 'package:loan_app/core/utils/validators.dart';

void main() {
  test('accepts a valid Indian mobile number', () {
    expect(Validators.mobileNumber('9876543210'), isNull);
  });

  test('rejects empty, short and wrongly prefixed numbers', () {
    expect(Validators.mobileNumber(''), isNotNull);
    expect(Validators.mobileNumber('98765'), isNotNull);
    expect(Validators.mobileNumber('5876543210'), isNotNull);
  });
}
