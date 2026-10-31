import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:loan_app/core/network/api_client.dart';
import 'package:loan_app/core/theme/app_theme.dart';
import 'package:loan_app/core/utils/app_formatters.dart';
import 'package:loan_app/data/models/loan_application.dart';
import 'package:loan_app/data/models/loan_quote.dart';
import 'package:loan_app/data/repositories/loan_repository.dart';
import 'package:loan_app/modules/loan_calculator/loan_calculator_controller.dart';
import 'package:loan_app/modules/loan_calculator/loan_calculator_view.dart';

class _NoApi implements ApiClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeLoans extends LoanRepository {
  _FakeLoans() : super(_NoApi());

  final List<({int amount, int tenure})> calls = [];

  @override
  Future<LoanQuote> calculate({
    required int amount,
    required int tenureMonths,
  }) async {
    calls.add((amount: amount, tenure: tenureMonths));
    return LoanQuote(
      emi: amount / tenureMonths,
      totalPayable: amount * 1.1,
      totalInterest: amount * 0.1,
      interestRate: 12,
    );
  }
}

void main() {
  tearDown(Get.reset);

  testWidgets('dragging a slider sends one request after the pause', (
    tester,
  ) async {
    final loans = _FakeLoans();
    final controller = LoanCalculatorController(loans)..onInit();
    await tester.pump();
    expect(loans.calls, hasLength(1)); // initial quote

    controller.onAmountSliderChanged(100000);
    controller.onAmountSliderChanged(150000);
    controller.onAmountSliderChanged(200000);
    await tester.pump(const Duration(milliseconds: 300));
    expect(loans.calls, hasLength(1));

    await tester.pump(const Duration(milliseconds: 200));
    expect(loans.calls, hasLength(2));
    expect(loans.calls.last.amount, 200000);
    expect(controller.amountText.text, '200000');
    expect(controller.quote.value?.interestRate, 12);

    controller.onClose();
  });

  testWidgets('typed values outside the limits are ignored then clamped', (
    tester,
  ) async {
    final loans = _FakeLoans();
    final controller = LoanCalculatorController(loans)..onInit();
    await tester.pump();

    controller.onAmountTyped('900');
    controller.onTenureTyped('99');
    await tester.pump(const Duration(seconds: 1));
    expect(loans.calls, hasLength(1));

    controller.amountText.text = '900';
    controller.finishAmountEditing();
    controller.tenureText.text = '99';
    controller.finishTenureEditing();
    await tester.pump(const Duration(seconds: 1));

    expect(controller.amount.value, 10000);
    expect(controller.tenureMonths.value, 60);
    expect(loans.calls.last, (amount: 10000, tenure: 60));

    controller.onClose();
  });

  testWidgets('calculator screen shows the rate and quote from the backend', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(786, 1844);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    Get.put(LoanCalculatorController(_FakeLoans()));
    await tester.pumpWidget(
      GetMaterialApp(theme: AppTheme.light, home: const LoanCalculatorView()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Interest Rate 12% p.a.'), findsOneWidget);
    expect(find.text('Total Payable'), findsOneWidget);
    expect(find.text('₹55,000.00'), findsOneWidget);
    expect(find.byType(Slider), findsNWidgets(2));
  });

  test('formatters use Indian digit grouping', () {
    expect(AppFormatters.currency(500000), '₹5,00,000');
    expect(AppFormatters.currencyPrecise(4442.4), '₹4,442.40');
  });

  test('loan application maps the backend status to a label', () {
    final loan = LoanApplication.fromJson({
      '_id': 'l1',
      'applicationNumber': 'CS123',
      'amount': 50000,
      'tenureMonths': 12,
      'status': 'under_review',
    });

    expect(loan.statusLabel, 'Under Review');
  });
}
