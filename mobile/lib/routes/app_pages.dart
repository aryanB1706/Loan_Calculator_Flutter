import 'package:get/get.dart';

import '../modules/auth/auth_binding.dart';
import '../modules/auth/auth_view.dart';
import '../modules/home/home_binding.dart';
import '../modules/home/home_view.dart';
import '../modules/loan_apply/loan_apply_binding.dart';
import '../modules/loan_apply/loan_apply_view.dart';
import '../modules/loan_calculator/loan_calculator_binding.dart';
import '../modules/loan_calculator/loan_calculator_view.dart';
import '../modules/loan_status/loan_status_binding.dart';
import '../modules/loan_status/loan_status_view.dart';
import '../modules/notifications/notifications_binding.dart';
import '../modules/notifications/notifications_view.dart';
import '../modules/profile/profile_binding.dart';
import '../modules/profile/profile_view.dart';
import 'app_routes.dart';

class AppPages {
  const AppPages._();

  static const String initialRoute = AppRoutes.auth;

  static final List<GetPage> routes = [
    GetPage(
      name: AppRoutes.auth,
      page: () => const AuthView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfileView(),
      binding: ProfileBinding(),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.loanCalculator,
      page: () => const LoanCalculatorView(),
      binding: LoanCalculatorBinding(),
    ),
    GetPage(
      name: AppRoutes.loanApply,
      page: () => const LoanApplyView(),
      binding: LoanApplyBinding(),
    ),
    GetPage(
      name: AppRoutes.loanStatus,
      page: () => const LoanStatusView(),
      binding: LoanStatusBinding(),
    ),
    GetPage(
      name: AppRoutes.notifications,
      page: () => const NotificationsView(),
      binding: NotificationsBinding(),
    ),
  ];
}
