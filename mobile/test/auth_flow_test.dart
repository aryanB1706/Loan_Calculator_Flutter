import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:loan_app/core/network/api_client.dart';
import 'package:loan_app/core/storage/session_service.dart';
import 'package:loan_app/core/storage/token_storage.dart';
import 'package:loan_app/core/theme/app_theme.dart';
import 'package:loan_app/data/models/auth_session.dart';
import 'package:loan_app/data/models/otp_request_result.dart';
import 'package:loan_app/data/repositories/auth_repository.dart';
import 'package:loan_app/modules/auth/auth_controller.dart';
import 'package:loan_app/modules/auth/auth_view.dart';
import 'package:loan_app/modules/otp/otp_arguments.dart';
import 'package:loan_app/modules/otp/otp_controller.dart';

class _FakeRepository extends AuthRepository {
  _FakeRepository() : super(_NoApi());

  String? lastOtp;

  @override
  Future<OtpRequestResult> sendOtp(String phone) async =>
      const OtpRequestResult(resendAfterSeconds: 30);

  @override
  Future<AuthSession> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    lastOtp = otp;
    return const AuthSession(
      accessToken: 'a',
      refreshToken: 'r',
      profileCompleted: true,
    );
  }
}

class _NoApi implements ApiClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MemoryStorage extends TokenStorage {
  String? access;
  bool completed = false;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async => access = accessToken;

  @override
  Future<void> saveProfileCompleted(bool value) async => completed = value;
}

void main() {
  tearDown(Get.reset);

  testWidgets('login sheet renders without overflow and blocks bad numbers', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final controller = Get.put(AuthController(_FakeRepository()));

    await tester.pumpWidget(
      GetMaterialApp(theme: AppTheme.light, home: const AuthView()),
    );

    expect(find.text('Welcome to Credit Sea!'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), '123');
    await tester.tap(find.text('Request OTP'));
    await tester.pump();

    expect(find.text('Enter a valid 10-digit mobile number'), findsOneWidget);
    expect(controller.isLoading.value, isFalse);
  });

  test('entering the 6th digit auto-submits and stores the session', () async {
    final repository = _FakeRepository();
    final session = SessionService(_MemoryStorage());
    final controller = OtpController(
      repository,
      session,
      const OtpArguments(phone: '9876543210', resendAfterSeconds: 30),
    );

    controller.otpTextController.text = '123456';
    controller.onOtpChanged('123456');
    await Future<void>.delayed(Duration.zero);

    expect(repository.lastOtp, '123456');
    expect(session.isLoggedIn.value, isTrue);
    expect(session.profileCompleted.value, isTrue);

    controller.onClose();
  });
}
