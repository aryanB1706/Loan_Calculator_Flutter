import 'package:get/get.dart';

import '../modules/applications/applications_binding.dart';
import '../modules/applications/applications_view.dart';
import '../modules/auth/auth_binding.dart';
import '../modules/auth/auth_view.dart';
import '../modules/home/home_binding.dart';
import '../modules/home/home_view.dart';
import '../modules/loan_apply/loan_apply_binding.dart';
import '../modules/loan_apply/loan_apply_view.dart';
import '../modules/loan_calculator/loan_calculator_binding.dart';
import '../modules/loan_calculator/loan_calculator_view.dart';
import '../modules/loan_eligibility/loan_eligibility_binding.dart';
import '../modules/loan_eligibility/loan_eligibility_view.dart';
import '../modules/loan_status/loan_status_binding.dart';
import '../modules/loan_success/loan_success_binding.dart';
import '../modules/loan_success/loan_success_view.dart';
import '../modules/loan_status/loan_status_view.dart';
import '../modules/notifications/notifications_binding.dart';
import '../modules/notifications/notifications_view.dart';
import '../modules/otp/otp_binding.dart';
import '../modules/otp/otp_view.dart';
import '../modules/profile/profile_binding.dart';
import '../modules/profile_setup/profile_setup_binding.dart';
import '../modules/profile_setup/profile_setup_view.dart';
import '../modules/profile/profile_view.dart';
import '../modules/splash/splash_binding.dart';
import '../modules/splash/splash_view.dart';
import '../data/models/loan_application.dart';
import '../data/models/loan_offer.dart';
import '../data/models/loan_terms.dart';
import 'app_routes.dart';
import 'guarded_page.dart';

class AppPages {
  const AppPages._();

  static const String initialRoute = AppRoutes.splash;

  static final List<GetPage> routes = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: AppRoutes.auth,
      page: () => const AuthView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.otp,
      page: () => const OtpView(),
      binding: OtpBinding(),
    ),
    GetPage(
      name: AppRoutes.profileSetup,
      page: () => const ProfileSetupView(),
      binding: ProfileSetupBinding(),
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
    guardedPage<LoanTerms>(
      name: AppRoutes.loanEligibility,
      page: () => const LoanEligibilityView(),
      binding: LoanEligibilityBinding(),
    ),
    guardedPage<LoanApplication>(
      name: AppRoutes.loanSuccess,
      page: () => const LoanSuccessView(),
      binding: LoanSuccessBinding(),
    ),
    guardedPage<LoanOffer>(
      name: AppRoutes.loanApply,
      page: () => const LoanApplyView(),
      binding: LoanApplyBinding(),
    ),
    GetPage(
      name: AppRoutes.applications,
      page: () => const ApplicationsView(),
      binding: ApplicationsBinding(),
    ),
    guardedPage<LoanApplication>(
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
