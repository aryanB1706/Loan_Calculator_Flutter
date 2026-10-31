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

  String get firstName {
    final name = user.value?.fullName?.trim() ?? '';
    return name.isEmpty ? '' : name.split(' ').first;
  }

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    errorMessage.value = null;

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
    } catch (error, stack) {
      logUnexpectedError('home.load', error, stack);
      errorMessage.value = 'Something went wrong. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  void openProfile() => Get.toNamed(AppRoutes.profile);

  void openCalculator() => Get.toNamed(AppRoutes.loanCalculator);

  void openLatestApplication() {
    Get.toNamed(AppRoutes.loanStatus, arguments: latestApplication.value);
  }
}
