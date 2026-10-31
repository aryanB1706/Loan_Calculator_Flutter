import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:loan_app/core/network/api_client.dart';
import 'package:loan_app/data/models/credit_score.dart';
import 'package:loan_app/data/models/loan_application.dart';
import 'package:loan_app/data/models/user_model.dart';
import 'package:loan_app/data/repositories/loan_repository.dart';
import 'package:loan_app/data/repositories/user_repository.dart';
import 'package:loan_app/modules/home/home_controller.dart';
import 'package:loan_app/modules/loan_success/loan_success_controller.dart';
import 'package:loan_app/routes/app_routes.dart';

class _NoApi implements ApiClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeUsers extends UserRepository {
  _FakeUsers() : super(_NoApi());

  @override
  Future<UserModel> getMe() async => const UserModel(fullName: 'Asha Rao');

  @override
  Future<CreditScore> getCreditScore() async =>
      const CreditScore(score: 650, band: 'fair');
}

class _FakeLoans extends LoanRepository {
  _FakeLoans() : super(_NoApi());

  int latestCalls = 0;

  @override
  Future<LoanApplication?> latestApplication() async {
    latestCalls++;
    return null;
  }
}

const _application = LoanApplication(
  id: '1',
  applicationNumber: 'LN-1',
  amount: 50000,
  tenureMonths: 12,
  status: 'submitted',
);

void main() {
  tearDown(Get.reset);

  testWidgets('success goes back to the same Home and Home reloads', (
    tester,
  ) async {
    final loans = _FakeLoans();
    final home = HomeController(_FakeUsers(), loans);

    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: AppRoutes.home,
        getPages: [
          GetPage(name: AppRoutes.home, page: () => const Text('HOME')),
          GetPage(
            name: AppRoutes.loanCalculator,
            page: () => const Text('calc'),
          ),
          GetPage(
            name: AppRoutes.loanSuccess,
            page: () => const Text('success'),
          ),
          GetPage(name: AppRoutes.loanStatus, page: () => const Text('status')),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await home.load();
    expect(loans.latestCalls, 1);

    home.openCalculator();
    await tester.pumpAndSettle();
    Get.toNamed(AppRoutes.loanSuccess);
    await tester.pumpAndSettle();

    LoanSuccessController(_application).goHome();
    await tester.pumpAndSettle();

    expect(find.text('HOME'), findsOneWidget);
    expect(loans.latestCalls, 2);
  });

  testWidgets('track status keeps Home underneath the status page', (
    tester,
  ) async {
    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: AppRoutes.home,
        getPages: [
          GetPage(name: AppRoutes.home, page: () => const Text('HOME')),
          GetPage(
            name: AppRoutes.loanSuccess,
            page: () => const Text('success'),
          ),
          GetPage(name: AppRoutes.loanStatus, page: () => const Text('status')),
        ],
      ),
    );
    Get.toNamed(AppRoutes.loanSuccess);
    await tester.pumpAndSettle();

    LoanSuccessController(_application).trackStatus();
    await tester.pumpAndSettle();
    expect(find.text('status'), findsOneWidget);

    Get.back();
    await tester.pumpAndSettle();
    expect(find.text('HOME'), findsOneWidget);
  });
}
