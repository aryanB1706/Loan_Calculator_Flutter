import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../core/constants/auth_constants.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/debug_log.dart';
import '../../core/storage/session_service.dart';
import '../../data/repositories/auth_repository.dart';
import 'otp_arguments.dart';

/// OTP screen: verifies the code, stores the session and routes onward.
class OtpController extends GetxController {
  OtpController(this._repository, this._session, OtpArguments arguments)
    : phone = arguments.phone,
      _initialCooldown = arguments.resendAfterSeconds;

  final AuthRepository _repository;
  final SessionService _session;
  final int _initialCooldown;

  final String phone;
  final otpTextController = TextEditingController();
  final RxBool isLoading = false.obs;
  final RxInt secondsLeft = 0.obs;
  final RxnString errorMessage = RxnString();

  Timer? _timer;

  bool get canResend => secondsLeft.value == 0 && !isLoading.value;

  String get displayPhone => '${AuthConstants.countryCode} $phone';

  String get countdownText {
    final minutes = (secondsLeft.value ~/ 60).toString().padLeft(2, '0');
    final seconds = (secondsLeft.value % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void onInit() {
    super.onInit();
    _startCountdown(_initialCooldown);
  }

  @override
  void onClose() {
    _timer?.cancel();
    otpTextController.dispose();
    super.onClose();
  }

  void onOtpChanged(String value) {
    errorMessage.value = null;

    if (value.length == AuthConstants.otpLength) {
      verify();
    }
  }

  Future<void> verify() async {
    final otp = otpTextController.text;

    if (isLoading.value) {
      return;
    }
    if (otp.length != AuthConstants.otpLength) {
      errorMessage.value = 'Enter the ${AuthConstants.otpLength}-digit OTP';
      return;
    }

    isLoading.value = true;
    errorMessage.value = null;

    try {
      final session = await _repository.verifyOtp(phone: phone, otp: otp);
      await _session.saveSession(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
        profileCompleted: session.profileCompleted,
      );
      Get.offAllNamed(_session.landingRoute);
    } on ApiException catch (error) {
      _showFailure(error.message);
    } catch (error, stack) {
      logUnexpectedError('otp_c.verify', error, stack);
      _showFailure('Something went wrong. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resend() async {
    if (!canResend) {
      return;
    }

    isLoading.value = true;
    errorMessage.value = null;

    try {
      final result = await _repository.sendOtp(phone);
      otpTextController.clear();
      _startCountdown(result.resendAfterSeconds);
    } on ApiException catch (error) {
      errorMessage.value = error.message;
    } catch (error, stack) {
      logUnexpectedError('otp_c.resend', error, stack);
      errorMessage.value = 'Something went wrong. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  // A wrong code is cleared so the user can retype without deleting digits.
  void _showFailure(String message) {
    errorMessage.value = message;
    otpTextController.clear();
  }

  void _startCountdown(int seconds) {
    _timer?.cancel();
    secondsLeft.value = seconds;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsLeft.value <= 1) {
        secondsLeft.value = 0;
        timer.cancel();
        return;
      }
      secondsLeft.value--;
    });
  }
}
