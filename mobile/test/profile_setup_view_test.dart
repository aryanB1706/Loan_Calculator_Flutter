import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:loan_app/core/network/api_client.dart';
import 'package:loan_app/core/storage/session_service.dart';
import 'package:loan_app/core/storage/token_storage.dart';
import 'package:loan_app/core/theme/app_theme.dart';
import 'package:loan_app/data/repositories/user_repository.dart';
import 'package:loan_app/modules/profile_setup/profile_setup_controller.dart';
import 'package:loan_app/modules/profile_setup/profile_setup_view.dart';

class _NoApi implements ApiClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  tearDown(Get.reset);

  testWidgets('blocks an invalid first step, then walks through all steps', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(786, 1844);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    final controller = Get.put(
      ProfileSetupController(
        UserRepository(_NoApi()),
        SessionService(TokenStorage()),
        null,
      ),
    );
    await tester.pumpWidget(
      GetMaterialApp(theme: AppTheme.light, home: const ProfileSetupView()),
    );

    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(find.text('Please enter your first name'), findsOneWidget);
    expect(controller.step.value, 0);

    for (final step in [1, 2, 3]) {
      controller.step.value = step;
      await tester.pump();
      expect(
        find.text(ProfileSetupController.stepTitles[step]),
        findsOneWidget,
      );
    }
    expect(find.text('Submit'), findsOneWidget);
  });
}
