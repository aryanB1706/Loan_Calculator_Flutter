import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:loan_app/data/models/loan_application.dart';
import 'package:loan_app/routes/app_routes.dart';
import 'package:loan_app/routes/guarded_page.dart';

class _CountingBinding extends Bindings {
  static int calls = 0;

  @override
  void dependencies() => calls++;
}

const _loan = LoanApplication(
  id: '1',
  applicationNumber: 'LN-1',
  amount: 50000,
  tenureMonths: 12,
  status: 'submitted',
);

Widget _app(String initialRoute) {
  return GetMaterialApp(
    initialRoute: initialRoute,
    getPages: [
      GetPage(name: AppRoutes.splash, page: () => const Text('SPLASH')),
      GetPage(name: AppRoutes.home, page: () => const Text('HOME')),
      guardedPage<LoanApplication>(
        name: AppRoutes.loanStatus,
        page: () => const Text('DETAILS'),
        binding: _CountingBinding(),
      ),
    ],
  );
}

void main() {
  setUp(() => _CountingBinding.calls = 0);
  tearDown(Get.reset);

  testWidgets('opened without arguments (browser refresh) it goes to splash', (
    tester,
  ) async {
    await tester.pumpWidget(_app(AppRoutes.loanStatus));
    await tester.pumpAndSettle();

    expect(find.text('SPLASH'), findsOneWidget);
    expect(find.text('DETAILS'), findsNothing);
    expect(_CountingBinding.calls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opened with the expected arguments it shows the page', (
    tester,
  ) async {
    await tester.pumpWidget(_app(AppRoutes.home));
    await tester.pumpAndSettle();

    Get.toNamed(AppRoutes.loanStatus, arguments: _loan);
    await tester.pumpAndSettle();

    expect(find.text('DETAILS'), findsOneWidget);
    expect(_CountingBinding.calls, 1);
  });
}
