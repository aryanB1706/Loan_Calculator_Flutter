import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'loan_status_controller.dart';

class LoanStatusView extends GetView<LoanStatusController> {
  const LoanStatusView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Loan Status')));
  }
}
