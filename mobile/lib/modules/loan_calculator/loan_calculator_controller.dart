import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../core/constants/loan_constants.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/debug_log.dart';
import '../../routes/app_routes.dart';
import '../../data/models/loan_quote.dart';
import '../../data/models/loan_terms.dart';
import '../../data/repositories/loan_repository.dart';

/// Keeps the amount and tenure in sync between sliders and text boxes and asks
/// the backend for a quote shortly after the user stops changing them.
class LoanCalculatorController extends GetxController {
  LoanCalculatorController(this._repository);

  final LoanRepository _repository;

  // Waits for the user to pause so dragging a slider sends one request, not hundreds.
  static const Duration _debounceTime = Duration(milliseconds: 400);

  final RxInt amount = LoanLimits.defaultAmount.obs;
  final RxInt tenureMonths = LoanLimits.defaultTenureMonths.obs;
  final amountText = TextEditingController();
  final tenureText = TextEditingController();

  final Rxn<LoanQuote> quote = Rxn<LoanQuote>();
  final RxBool isLoading = false.obs;
  final RxnString errorMessage = RxnString();

  Timer? _debounce;
  int _latestRequest = 0;

  @override
  void onInit() {
    super.onInit();
    _syncTexts();
    _fetchQuote();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    amountText.dispose();
    tenureText.dispose();
    super.onClose();
  }

  void onAmountSliderChanged(double value) {
    amount.value = value.round();
    amountText.text = '${amount.value}';
    _scheduleQuote();
  }

  void onTenureSliderChanged(double value) {
    tenureMonths.value = value.round();
    tenureText.text = '${tenureMonths.value}';
    _scheduleQuote();
  }

  // While typing, only values inside the allowed range update the quote; the
  // final clamp happens when the user finishes editing.
  void onAmountTyped(String text) {
    final value = int.tryParse(text);
    if (value != null &&
        _isInRange(value, LoanLimits.minAmount, LoanLimits.maxAmount)) {
      amount.value = value;
      _scheduleQuote();
    }
  }

  void onTenureTyped(String text) {
    final value = int.tryParse(text);
    if (value != null &&
        _isInRange(
          value,
          LoanLimits.minTenureMonths,
          LoanLimits.maxTenureMonths,
        )) {
      tenureMonths.value = value;
      _scheduleQuote();
    }
  }

  void finishAmountEditing() {
    final value = int.tryParse(amountText.text) ?? amount.value;
    amount.value = value.clamp(LoanLimits.minAmount, LoanLimits.maxAmount);
    amountText.text = '${amount.value}';
    _scheduleQuote();
  }

  void finishTenureEditing() {
    final value = int.tryParse(tenureText.text) ?? tenureMonths.value;
    tenureMonths.value = value.clamp(
      LoanLimits.minTenureMonths,
      LoanLimits.maxTenureMonths,
    );
    tenureText.text = '${tenureMonths.value}';
    _scheduleQuote();
  }

  void checkEligibility() {
    Get.toNamed(
      AppRoutes.loanEligibility,
      arguments: LoanTerms(
        amount: amount.value,
        tenureMonths: tenureMonths.value,
      ),
    );
  }

  bool _isInRange(int value, int min, int max) => value >= min && value <= max;

  void _syncTexts() {
    amountText.text = '${amount.value}';
    tenureText.text = '${tenureMonths.value}';
  }

  void _scheduleQuote() {
    _debounce?.cancel();
    _debounce = Timer(_debounceTime, _fetchQuote);
  }

  Future<void> _fetchQuote() async {
    // Slow responses for old inputs must not overwrite a newer quote.
    final request = ++_latestRequest;
    isLoading.value = true;
    errorMessage.value = null;

    try {
      final result = await _repository.calculate(
        amount: amount.value,
        tenureMonths: tenureMonths.value,
      );
      if (request == _latestRequest) {
        quote.value = result;
      }
    } on ApiException catch (error) {
      if (request == _latestRequest) {
        errorMessage.value = error.message;
      }
    } catch (error, stack) {
      logUnexpectedError('calculator.fetchQuote', error, stack);
      if (request == _latestRequest) {
        errorMessage.value = 'Something went wrong. Please try again.';
      }
    } finally {
      if (request == _latestRequest) {
        isLoading.value = false;
      }
    }
  }
}
