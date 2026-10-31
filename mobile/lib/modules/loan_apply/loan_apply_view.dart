import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'loan_apply_controller.dart';

class LoanApplyView extends GetView<LoanApplyController> {
  const LoanApplyView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Loan Apply')));
  }
}
