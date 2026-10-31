import 'package:get/get.dart';

import '../../core/network/api_exception.dart';
import '../../core/utils/debug_log.dart';
import '../../data/models/credit_score.dart';
import '../../data/models/loan_application.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/loan_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../routes/app_routes.dart';

class HomeController extends GetxController {
  HomeController(this._users, this._loans);

  final UserRepository _users;
  final LoanRepository _loans;

  final Rxn<UserModel> user = Rxn<UserModel>();
  final Rxn<CreditScore> creditScore = Rxn<CreditScore>();
  final Rxn<LoanApplication> latestApplication = Rxn<LoanApplication>();
  final RxBool isLoading = true.obs;
  final RxnString errorMessage = RxnString();
  final RxBool isOffline = false.obs;

  String get firstName {
    final name = user.value?.fullName?.trim() ?? '';
    return name.isEmpty ? '' : name.split(' ').first;
  }

  @override
  void onInit() {
    super.onInit();
    load();
  }

  // Used by "Try again": shows the loader again, unlike a quiet pull-to-refresh.
  Future<void> retry() {
    isLoading.value = true;
    return load();
  }

  Future<void> load() async {
    errorMessage.value = null;
    isOffline.value = false;

    try {
      final results = await Future.wait([
        _users.getMe(),
        _users.getCreditScore(),
        _loans.latestApplication(),
      ]);
      user.value = results[0] as UserModel;
      creditScore.value = results[1] as CreditScore;
      latestApplication.value = results[2] as LoanApplication?;
    } on ApiException catch (error) {
      errorMessage.value = error.message;
      isOffline.value = error.isNetworkError;
    } catch (error, stack) {
      logUnexpectedError('home.load', error, stack);
      errorMessage.value = 'Something went wrong. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  // Each page below can change what Home shows (a new application, an edited
  // name), so Home reloads when the user comes back.
  Future<void> openProfile() => _openAndRefresh(AppRoutes.profile);

  Future<void> openCalculator() => _openAndRefresh(AppRoutes.loanCalculator);

  Future<void> openApplications() => _openAndRefresh(AppRoutes.applications);

  Future<void> openLatestApplication() {
    return _openAndRefresh(
      AppRoutes.loanStatus,
      arguments: latestApplication.value,
    );
  }

  Future<void> _openAndRefresh(String route, {Object? arguments}) async {
    await Get.toNamed(route, arguments: arguments);
    await load();
  }
}
