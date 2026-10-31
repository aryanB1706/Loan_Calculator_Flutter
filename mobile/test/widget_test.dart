import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:loan_app/core/storage/session_service.dart';
import 'package:loan_app/core/storage/token_storage.dart';
import 'package:loan_app/modules/splash/splash_controller.dart';
import 'package:loan_app/modules/splash/splash_view.dart';

class _LoggedOutStorage extends TokenStorage {
  @override
  Future<String?> readAccessToken() async => null;
}

void main() {
  tearDown(Get.reset);

  testWidgets('splash shows the logo while checking the session', (
    tester,
  ) async {
    final session = SessionService(_LoggedOutStorage());
    Get.put(SplashController(session));

    await tester.pumpWidget(
      GetMaterialApp(
        home: const SplashView(),
        getPages: [GetPage(name: '/auth', page: () => const Scaffold())],
      ),
    );

    expect(find.byType(Image), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
  });
}
