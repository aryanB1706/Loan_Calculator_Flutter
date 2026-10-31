import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../core/network/api_exception.dart';
import '../../core/utils/debug_log.dart';
import '../../data/repositories/auth_repository.dart';
import '../../routes/app_routes.dart';
import '../otp/otp_arguments.dart';

/// Mobile number screen: validates the number and requests an OTP.
class AuthController extends GetxController {
  AuthController(this._repository);

  final AuthRepository _repository;

  final formKey = GlobalKey<FormState>();
  final phoneController = TextEditingController();
  final RxBool isLoading = false.obs;
  final RxBool termsAccepted = true.obs;
  final RxnString errorMessage = RxnString();

  @override
  void onClose() {
    phoneController.dispose();
    super.onClose();
  }

  void toggleTerms(bool? value) {
    termsAccepted.value = value ?? false;
  }

  Future<void> requestOtp() async {
    if (isLoading.value) {
      return;
    }

    errorMessage.value = null;

    if (!formKey.currentState!.validate()) {
      return;
    }
    if (!termsAccepted.value) {
      errorMessage.value = 'Please accept the privacy policies and terms.';
      return;
    }

    final phone = phoneController.text.trim();
    isLoading.value = true;

    try {
      final result = await _repository.sendOtp(phone);
      Get.toNamed(
        AppRoutes.otp,
        arguments: OtpArguments(
          phone: phone,
          resendAfterSeconds: result.resendAfterSeconds,
        ),
      );
    } on ApiException catch (error) {
      errorMessage.value = error.message;
    } catch (error, stack) {
      logUnexpectedError('auth_c.requestOtp', error, stack);
      errorMessage.value = 'Something went wrong. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }
}
