import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'notifications_controller.dart';

class NotificationsView extends GetView<NotificationsController> {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Notifications')));
  }
}
