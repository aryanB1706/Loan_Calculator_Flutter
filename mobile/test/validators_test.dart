import 'package:flutter_test/flutter_test.dart';
import 'package:loan_app/core/utils/validators.dart';

void main() {
  profileValidatorTests();

  test('accepts a valid Indian mobile number', () {
    expect(Validators.mobileNumber('9876543210'), isNull);
  });

  test('rejects empty, short and wrongly prefixed numbers', () {
    expect(Validators.mobileNumber(''), isNotNull);
    expect(Validators.mobileNumber('98765'), isNotNull);
    expect(Validators.mobileNumber('5876543210'), isNotNull);
  });
}

void profileValidatorTests() {
  group('profile validators', () {
    test('PAN needs five letters, four digits and a letter', () {
      expect(Validators.pan('ABCDE1234F'), isNull);
      expect(Validators.pan('abcde1234f'), isNull);
      expect(Validators.pan('ABCD12345F'), isNotNull);
      expect(Validators.pan(''), isNotNull);
    });

    test('email must look like an address', () {
      expect(Validators.email('a@b.com'), isNull);
      expect(Validators.email('a@b'), isNotNull);
      expect(Validators.email('nope'), isNotNull);
    });

    test('income must be a positive number', () {
      expect(Validators.monthlyIncome('50000'), isNull);
      expect(Validators.monthlyIncome('0'), isNotNull);
      expect(Validators.monthlyIncome(''), isNotNull);
    });

    test('date of birth enforces age 18 on the exact birthday', () {
      final today = DateTime(2026, 6, 15);

      expect(
        Validators.dateOfBirth(DateTime(2008, 6, 15), today: today),
        isNull,
      );
      expect(
        Validators.dateOfBirth(DateTime(2008, 6, 16), today: today),
        isNotNull,
      );
      expect(Validators.dateOfBirth(null, today: today), isNotNull);
    });
  });
}
