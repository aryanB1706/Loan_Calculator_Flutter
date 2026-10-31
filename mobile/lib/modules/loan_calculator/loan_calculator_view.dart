import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'loan_calculator_controller.dart';

class LoanCalculatorView extends GetView<LoanCalculatorController> {
  const LoanCalculatorView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Loan Calculator')));
  }
}
