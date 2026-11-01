// Renders the real screens to PNG files for the README.
//
//   flutter test tool/screenshots_test.dart --update-goldens
//
// It lives in tool/ (not test/) so a normal `flutter test` never runs it. The
// screens are the app's own widgets; only the data comes from fake repositories
// because no backend or device is involved.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:loan_app/core/network/api_client.dart';
import 'package:loan_app/core/storage/session_service.dart';
import 'package:loan_app/core/storage/token_storage.dart';
import 'package:loan_app/core/theme/app_theme.dart';
import 'package:loan_app/data/models/credit_score.dart';
import 'package:loan_app/data/models/eligibility_result.dart';
import 'package:loan_app/data/models/loan_application.dart';
import 'package:loan_app/data/models/loan_quote.dart';
import 'package:loan_app/data/models/loan_terms.dart';
import 'package:loan_app/data/models/repayment.dart';
import 'package:loan_app/data/models/status_change.dart';
import 'package:loan_app/data/models/user_model.dart';
import 'package:loan_app/data/repositories/auth_repository.dart';
import 'package:loan_app/data/repositories/loan_repository.dart';
import 'package:loan_app/data/repositories/user_repository.dart';
import 'package:loan_app/modules/auth/auth_controller.dart';
import 'package:loan_app/modules/auth/auth_view.dart';
import 'package:loan_app/modules/home/home_controller.dart';
import 'package:loan_app/modules/home/home_view.dart';
import 'package:loan_app/modules/loan_calculator/loan_calculator_controller.dart';
import 'package:loan_app/modules/loan_calculator/loan_calculator_view.dart';
import 'package:loan_app/modules/loan_eligibility/loan_eligibility_controller.dart';
import 'package:loan_app/modules/loan_eligibility/loan_eligibility_view.dart';
import 'package:loan_app/modules/loan_status/loan_status_controller.dart';
import 'package:loan_app/modules/loan_status/loan_status_view.dart';
import 'package:loan_app/modules/otp/otp_arguments.dart';
import 'package:loan_app/modules/otp/otp_controller.dart';
import 'package:loan_app/modules/otp/otp_view.dart';

class _NoApi implements ApiClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _NoStorage implements TokenStorage {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

const _quote = LoanQuote(
  emi: 8884.88,
  totalPayable: 106618.56,
  totalInterest: 6618.56,
  interestRate: 12,
);

final _application = LoanApplication(
  id: 'l1',
  applicationNumber: 'LN-2026-000123',
  amount: 100000,
  tenureMonths: 12,
  status: 'disbursed',
  emi: 8884.88,
  totalPayable: 106618.56,
  interestRate: 12,
  purpose: 'Home renovation',
  statusHistory: [
    StatusChange(
      status: 'submitted',
      note: 'Application submitted',
      changedAt: DateTime(2026, 10, 28, 10, 5),
    ),
    StatusChange(
      status: 'under_review',
      note: 'Picked up for review',
      changedAt: DateTime(2026, 10, 28, 15, 30),
    ),
    StatusChange(
      status: 'approved',
      note: 'Auto-approved: eligibility and credit score checks passed.',
      changedAt: DateTime(2026, 10, 29, 9, 12),
    ),
    StatusChange(
      status: 'disbursed',
      note: 'Loan disbursed',
      changedAt: DateTime(2026, 10, 30, 11, 0),
    ),
  ],
);

class _FakeLoans extends LoanRepository {
  _FakeLoans() : super(_NoApi());

  @override
  Future<LoanQuote> calculate({
    required int amount,
    required int tenureMonths,
  }) async => _quote;

  @override
  Future<EligibilityResult> checkEligibility(LoanTerms terms) async =>
      const EligibilityResult(
        eligible: true,
        maxEligibleAmount: 500000,
        reasons: [],
      );

  @override
  Future<LoanApplication?> latestApplication() async => _application;

  @override
  Future<LoanApplication> getApplication(String id) async => _application;

  @override
  Future<List<Repayment>> repayments(String loanId) async => [
    for (var i = 1; i <= 12; i++)
      Repayment(
        installmentNumber: i,
        dueDate: DateTime(2026, 11 + i - 1, 30),
        amount: 8884.88,
        status: i == 1 ? 'paid' : 'pending',
        paidAt: i == 1 ? DateTime(2026, 11, 2) : null,
      ),
  ];
}

class _FakeUsers extends UserRepository {
  _FakeUsers() : super(_NoApi());

  @override
  Future<UserModel> getMe() async => const UserModel(fullName: 'Asha Verma');

  @override
  Future<CreditScore> getCreditScore() async =>
      const CreditScore(score: 660, band: 'fair');
}

Future<void> _loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final file in files) {
    loader.addFont(
      File(file).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
    );
  }
  await loader.load();
}

Future<void> _shot(
  WidgetTester tester,
  String name,
  Widget screen, {
  VoidCallback? dispose,
}) async {
  await tester.pumpWidget(
    GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: screen,
    ),
  );
  // Asset images decode asynchronously, which the test clock does not wait for.
  await tester.runAsync(() async {
    final context = tester.element(find.byType(Scaffold).first);
    for (final image in ['logo', 'offer_coin', 'email_illustration']) {
      await precacheImage(AssetImage('assets/images/$image.png'), context);
    }
  });
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump(const Duration(milliseconds: 600));

  await expectLater(
    find.byType(GetMaterialApp),
    matchesGoldenFile('../../docs/screenshots/$name.png'),
  );

  // The framework requires the default again before a test body ends.
  debugDisableShadows = true;
  dispose?.call();
  Get.reset();
}

void main() {
  setUpAll(() async {
    await _loadFont('Montserrat', [
      'assets/fonts/Montserrat-Regular.ttf',
      'assets/fonts/Montserrat-Medium.ttf',
      'assets/fonts/Montserrat-SemiBold.ttf',
    ]);
    final flutterRoot = Platform.environment['FLUTTER_ROOT']!;
    await _loadFont('MaterialIcons', [
      '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    ]);
  });

  setUp(() {
    // Tests draw shadows as solid shapes by default; the app uses soft ones.
    debugDisableShadows = false;
    // The size of the design frames (390 x 844 logical pixels, 2x).
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first
      ..physicalSize = const Size(780, 1688)
      ..devicePixelRatio = 2;
  });

  tearDown(Get.reset);

  testWidgets('01 login', (tester) async {
    Get.put(AuthController(AuthRepository(_NoApi())));
    await _shot(tester, '01_login', const AuthView());
  });

  testWidgets('02 otp', (tester) async {
    final controller = Get.put(
      OtpController(
        AuthRepository(_NoApi()),
        SessionService(_NoStorage()),
        const OtpArguments(
          phone: '9876543210',
          resendAfterSeconds: 28,
          demoOtp: '123456',
        ),
      ),
    );
    await _shot(tester, '02_otp', const OtpView(), dispose: controller.onClose);
  });

  testWidgets('03 home', (tester) async {
    Get.put(HomeController(_FakeUsers(), _FakeLoans()));
    await _shot(tester, '03_home', const HomeView());
  });

  testWidgets('04 calculator', (tester) async {
    final controller = Get.put(LoanCalculatorController(_FakeLoans()));
    controller
      ..onAmountSliderChanged(100000)
      ..onTenureSliderChanged(12);
    await _shot(
      tester,
      '04_calculator',
      const LoanCalculatorView(),
      dispose: controller.onClose,
    );
  });

  testWidgets('05 offer', (tester) async {
    Get.put(
      LoanEligibilityController(
        _FakeLoans(),
        const LoanTerms(amount: 100000, tenureMonths: 12),
      ),
    );
    await _shot(tester, '05_offer', const LoanEligibilityView());
  });

  testWidgets('06 status', (tester) async {
    Get.put(LoanStatusController(_FakeLoans(), _application));
    await _shot(tester, '06_status', const LoanStatusView());
  });
}
