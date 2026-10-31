import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../core/network/api_exception.dart';
import '../../core/utils/debug_log.dart';
import '../../core/storage/session_service.dart';
import '../../core/utils/app_formatters.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';

/// Four-step profile form used for first-time setup and for editing.
/// All answers are kept here and sent to the backend in one PUT /users/me.
class ProfileSetupController extends GetxController {
  ProfileSetupController(this._repository, this._session, this._existing);

  final UserRepository _repository;
  final SessionService _session;
  final UserModel? _existing;

  static const int lastStep = 3;
  static const List<String> stepTitles = [
    'Personal Details',
    'Personal Email ID',
    'Verify PAN Number',
    'Employment Details',
  ];

  // Which step shows each backend field, so a server error can open the right one.
  static const Map<String, int> _stepOfField = {
    'fullName': 0,
    'dob': 0,
    'gender': 0,
    'email': 1,
    'pan': 2,
    'monthlyIncome': 3,
    'employmentType': 3,
    'city': 3,
  };

  final stepFormKeys = List.generate(
    lastStep + 1,
    (_) => GlobalKey<FormState>(),
  );

  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final dobText = TextEditingController();
  final email = TextEditingController();
  final pan = TextEditingController();
  final monthlyIncome = TextEditingController();
  final city = TextEditingController();

  final Rxn<String> gender = Rxn<String>();
  final Rxn<String> employmentType = Rxn<String>();
  final Rxn<DateTime> dob = Rxn<DateTime>();

  final RxInt step = 0.obs;
  final RxBool isSaving = false.obs;
  final RxMap<String, String> serverErrors = <String, String>{}.obs;
  final RxnString generalError = RxnString();

  bool get isEditing => _existing != null;
  bool get isLastStep => step.value == lastStep;
  bool get canGoBack => step.value > 0 || isEditing;

  // The oldest and youngest dates the date picker allows (18+ rule).
  DateTime get latestBirthDate {
    final now = DateTime.now();
    return DateTime(now.year - 18, now.month, now.day);
  }

  @override
  void onInit() {
    super.onInit();
    _prefillFromExisting();
  }

  @override
  void onClose() {
    for (final controller in [
      firstName,
      lastName,
      dobText,
      email,
      pan,
      monthlyIncome,
      city,
    ]) {
      controller.dispose();
    }
    super.onClose();
  }

  void setDob(DateTime value) {
    dob.value = value;
    dobText.text = AppFormatters.dobInput(value);
    clearServerError('dob');
  }

  void setGender(String? value) {
    gender.value = value;
    clearServerError('gender');
  }

  void setEmploymentType(String? value) {
    employmentType.value = value;
    clearServerError('employmentType');
  }

  void clearServerError(String field) {
    serverErrors.remove(field);
    generalError.value = null;
  }

  void goBack() {
    if (step.value > 0) {
      step.value--;
    } else {
      Get.back();
    }
  }

  Future<void> next() async {
    if (!stepFormKeys[step.value].currentState!.validate()) {
      return;
    }
    if (isLastStep) {
      await save();
    } else {
      step.value++;
    }
  }

  Future<void> save() async {
    if (isSaving.value) {
      return;
    }

    isSaving.value = true;
    serverErrors.clear();
    generalError.value = null;

    try {
      final saved = await _repository.updateMe(_buildProfile());
      await _session.markProfileCompleted(saved.profileCompleted);

      if (isEditing) {
        Get.back(result: saved);
      } else {
        Get.offAllNamed(_session.landingRoute);
      }
    } on ApiException catch (error) {
      _showServerError(error);
    } catch (error, stack) {
      logUnexpectedError('profile_setup_c.save', error, stack);
      generalError.value = 'Something went wrong. Please try again.';
    } finally {
      isSaving.value = false;
    }
  }

  UserModel _buildProfile() {
    return UserModel(
      fullName: '${firstName.text.trim()} ${lastName.text.trim()}',
      dob: dob.value,
      gender: gender.value,
      pan: pan.text.trim().toUpperCase(),
      email: email.text.trim(),
      monthlyIncome: num.parse(monthlyIncome.text.trim()),
      employmentType: employmentType.value,
      city: city.text.trim(),
    );
  }

  void _showServerError(ApiException error) {
    final fieldErrors = error.fieldErrors;
    serverErrors.assignAll(fieldErrors);

    if (fieldErrors.isEmpty) {
      generalError.value = error.message;
      return;
    }

    // Open the earliest step that has an error so the user sees it first.
    final steps = fieldErrors.keys.map(
      (field) => _stepOfField[field] ?? lastStep,
    );
    step.value = steps.reduce((a, b) => a < b ? a : b);
  }

  void _prefillFromExisting() {
    final user = _existing;
    if (user == null) {
      return;
    }

    final names = (user.fullName ?? '').split(' ');
    firstName.text = names.first;
    lastName.text = names.skip(1).join(' ');
    email.text = user.email ?? '';
    pan.text = user.pan ?? '';
    monthlyIncome.text = user.monthlyIncome?.toString() ?? '';
    city.text = user.city ?? '';
    gender.value = user.gender;
    employmentType.value = user.employmentType;

    if (user.dob != null) {
      setDob(user.dob!);
    }
  }
}
