import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:loan_app/core/network/api_client.dart';
import 'package:loan_app/core/storage/session_service.dart';
import 'package:loan_app/core/storage/token_storage.dart';
import 'package:loan_app/core/theme/app_theme.dart';
import 'package:loan_app/data/models/otp_request_result.dart';
import 'package:loan_app/data/repositories/auth_repository.dart';
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

Future<void> _pumpOtpScreen(WidgetTester tester, {String? demoOtp}) async {
  tester.view.physicalSize = const Size(786, 1844);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);

  Get.put(
    OtpController(
      AuthRepository(_NoApi()),
      SessionService(_NoStorage()),
      OtpArguments(
        phone: '9876543210',
        resendAfterSeconds: 30,
        demoOtp: demoOtp,
      ),
    ),
  );
  await tester.pumpWidget(
    GetMaterialApp(theme: AppTheme.light, home: const OtpView()),
  );
  await tester.pump();
}

// Disposing the controller cancels its resend countdown timer, which the test
// framework requires before a test ends.
void _closeScreen() => Get.find<OtpController>().onClose();

void main() {
  tearDown(Get.reset);

  test('send-otp response keeps demoOtp only when the backend sends it', () {
    final demo = OtpRequestResult.fromJson({
      'resendAfterSeconds': 30,
      'demoOtp': '123456',
    });
    final real = OtpRequestResult.fromJson({'resendAfterSeconds': 30});

    expect(demo.demoOtp, '123456');
    expect(real.demoOtp, isNull);
  });

  testWidgets('shows the demo OTP hint in demo mode', (tester) async {
    await _pumpOtpScreen(tester, demoOtp: '123456');

    expect(find.text('Demo mode: use OTP 123456'), findsOneWidget);
    _closeScreen();
  });

  testWidgets('shows no hint when the backend sends no demo OTP', (
    tester,
  ) async {
    await _pumpOtpScreen(tester);

    expect(find.textContaining('Demo mode'), findsNothing);
    _closeScreen();
  });
}
