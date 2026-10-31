import 'package:flutter_test/flutter_test.dart';
import 'package:loan_app/data/models/loan_quote.dart';
import 'package:loan_app/data/models/repayment.dart';

void main() {
  test('LoanQuote reads whole and fractional numbers from the backend', () {
    final quote = LoanQuote.fromJson({
      'emi': 4442.44,
      'totalPayable': 53309,
      'totalInterest': 3309.28,
      'interestRate': 12,
    });

    expect(quote.emi, 4442.44);
    expect(quote.totalPayable, 53309);
    expect(quote.interestRate, 12);
  });

  group('Repayment', () {
    final json = {
      'installmentNumber': 2,
      'dueDate': '2026-05-01T00:00:00.000Z',
      'amount': 4442.44,
      'status': 'pending',
    };

    test('parses an unpaid installment without a paidAt date', () {
      final repayment = Repayment.fromJson(json);

      expect(repayment.installmentNumber, 2);
      expect(repayment.isPending, isTrue);
      expect(repayment.paidAt, isNull);
    });

    test('parses a paid installment and its paidAt date', () {
      final repayment = Repayment.fromJson({
        ...json,
        'status': 'paid',
        'paidAt': '2026-04-30T10:00:00.000Z',
      });

      expect(repayment.isPending, isFalse);
      expect(repayment.paidAt, isNotNull);
    });

    test('flags late installments', () {
      expect(Repayment.fromJson({...json, 'status': 'late'}).isLate, isTrue);
    });
  });
}
