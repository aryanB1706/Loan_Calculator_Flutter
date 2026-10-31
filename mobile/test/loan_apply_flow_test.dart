import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:loan_app/core/network/api_client.dart';
import 'package:loan_app/core/network/api_exception.dart';
import 'package:loan_app/core/theme/app_theme.dart';
import 'package:loan_app/data/models/eligibility_result.dart';
import 'package:loan_app/data/models/loan_application.dart';
import 'package:loan_app/data/models/loan_offer.dart';
import 'package:loan_app/data/models/loan_quote.dart';
import 'package:loan_app/data/models/loan_terms.dart';
import 'package:loan_app/data/repositories/loan_repository.dart';
import 'package:loan_app/modules/loan_apply/loan_apply_controller.dart';
import 'package:loan_app/modules/loan_eligibility/loan_eligibility_controller.dart';
import 'package:loan_app/modules/loan_eligibility/loan_eligibility_view.dart';

class _NoApi implements ApiClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

const _terms = LoanTerms(amount: 50000, tenureMonths: 12);
const _quote = LoanQuote(
  emi: 4442.44,
  totalPayable: 53309.28,
  totalInterest: 3309.28,
  interestRate: 12,
);

class _FakeLoans extends LoanRepository {
  _FakeLoans({this.eligibility, this.applyError}) : super(_NoApi());

  final EligibilityResult? eligibility;
  final ApiException? applyError;

  @override
  Future<EligibilityResult> checkEligibility(LoanTerms terms) async =>
      eligibility!;

  @override
  Future<LoanQuote> calculate({
    required int amount,
    required int tenureMonths,
  }) async => _quote;

  @override
  Future<LoanApplication> apply(
    LoanTerms terms, {
    required String purpose,
  }) async => throw applyError!;
}

LoanApplyController _applyController(ApiException error) {
  return LoanApplyController(
    _FakeLoans(applyError: error),
    const LoanOffer(terms: _terms, quote: _quote),
  );
}

Future<void> _pumpEligibility(
  WidgetTester tester,
  EligibilityResult result,
) async {
  tester.view.physicalSize = const Size(786, 1844);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);

  Get.put(LoanEligibilityController(_FakeLoans(eligibility: result), _terms));
  await tester.pumpWidget(
    GetMaterialApp(theme: AppTheme.light, home: const LoanEligibilityView()),
  );
  await tester.pumpAndSettle();
}

void main() {
  tearDown(Get.reset);

  test('eligibility result maps the backend response', () {
    final result = EligibilityResult.fromJson({
      'eligible': false,
      'maxEligibleAmount': 200000,
      'reasons': ['Income too low'],
    });

    expect(result.eligible, isFalse);
    expect(result.reasons, ['Income too low']);
  });

  testWidgets('eligible users see the offer with EMI and total', (
    tester,
  ) async {
    await _pumpEligibility(
      tester,
      const EligibilityResult(
        eligible: true,
        maxEligibleAmount: 300000,
        reasons: [],
      ),
    );

    expect(find.text('Our Offerings'), findsOneWidget);
    expect(find.text('Accept Offer'), findsOneWidget);
    expect(find.textContaining('₹4,442.44'), findsOneWidget);
  });

  testWidgets('ineligible users see every reason in plain language', (
    tester,
  ) async {
    await _pumpEligibility(
      tester,
      const EligibilityResult(
        eligible: false,
        maxEligibleAmount: 150000,
        reasons: [
          'Your monthly income must be at least ₹15,000 to apply.',
          'EMI too high',
        ],
      ),
    );

    expect(find.text('You are not eligible for this loan'), findsOneWidget);
    expect(
      find.textContaining('monthly income must be at least'),
      findsOneWidget,
    );
    expect(find.text('EMI too high'), findsOneWidget);
    expect(find.text('Accept Offer'), findsNothing);
  });

  test('submitting without a purpose asks for one and sends nothing', () async {
    final controller = _applyController(const ApiException('never called'));

    await controller.submit();

    expect(controller.purposeError.value, isNotNull);
    expect(controller.errorMessage.value, isNull);
  });

  test('a duplicate active application is reported as a conflict', () async {
    final controller = _applyController(
      const ApiException(
        'You already have an active loan application',
        statusCode: 409,
      ),
    )..setPurpose('Education');

    await controller.submit();

    expect(controller.hasActiveApplication.value, isTrue);
    expect(controller.errorMessage.value, contains('active loan application'));
    expect(controller.isSubmitting.value, isFalse);
  });

  test('server-side ineligibility lists the reasons', () async {
    final controller = _applyController(
      const ApiException(
        'You are not eligible for this loan',
        statusCode: 422,
        errors: [
          {'field': 'eligibility', 'message': 'Reason one'},
          {'field': 'eligibility', 'message': 'Reason two'},
        ],
      ),
    )..setPurpose('Travel');

    await controller.submit();

    expect(controller.ineligibleReasons, ['Reason one', 'Reason two']);
    expect(controller.hasActiveApplication.value, isFalse);
  });
}
