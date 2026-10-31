import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_pages.dart';
import 'routes/initial_binding.dart';

class LoanApp extends StatelessWidget {
  const LoanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      initialBinding: InitialBinding(),
      initialRoute: AppPages.initialRoute,
      getPages: AppPages.routes,
      theme: AppTheme.light,
    );
  }
}
