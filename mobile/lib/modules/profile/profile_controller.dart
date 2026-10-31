import 'package:get/get.dart';

import '../../core/network/api_exception.dart';
import '../../core/utils/debug_log.dart';
import '../../core/storage/session_service.dart';
import '../../data/models/credit_score.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../routes/app_routes.dart';

class ProfileController extends GetxController {
  ProfileController(this._users, this._auth, this._session);

  final UserRepository _users;
  final AuthRepository _auth;
  final SessionService _session;

  final Rxn<UserModel> user = Rxn<UserModel>();
  final Rxn<CreditScore> creditScore = Rxn<CreditScore>();
  final RxBool isLoading = true.obs;
  final RxBool isLoggingOut = false.obs;
  final RxnString errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      final results = await Future.wait([
        _users.getMe(),
        _users.getCreditScore(),
      ]);
      user.value = results[0] as UserModel;
      creditScore.value = results[1] as CreditScore;
    } on ApiException catch (error) {
      errorMessage.value = error.message;
    } catch (error, stack) {
      logUnexpectedError('profile_c.load', error, stack);
      errorMessage.value = 'Something went wrong. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> editProfile() async {
    final updated = await Get.toNamed(
      AppRoutes.profileSetup,
      arguments: user.value,
    );

    if (updated is UserModel) {
      user.value = updated;
    }
  }

  Future<void> logout() async {
    if (isLoggingOut.value) {
      return;
    }

    isLoggingOut.value = true;

    try {
      await _auth.logout();
    } catch (_) {
      // The local session must end even if the server cannot be reached.
    }

    await _session.clearSession();
    Get.offAllNamed(AppRoutes.auth);
  }
}
