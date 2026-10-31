import 'package:flutter_test/flutter_test.dart';
import 'package:loan_app/core/network/api_client.dart';
import 'package:loan_app/core/network/api_exception.dart';
import 'package:loan_app/core/storage/session_service.dart';
import 'package:loan_app/core/storage/token_storage.dart';
import 'package:loan_app/data/models/user_model.dart';
import 'package:loan_app/data/repositories/user_repository.dart';
import 'package:loan_app/modules/profile_setup/profile_setup_controller.dart';

class _NoApi implements ApiClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FailingRepository extends UserRepository {
  _FailingRepository(this.error) : super(_NoApi());

  final ApiException error;

  @override
  Future<UserModel> updateMe(UserModel profile) async => throw error;
}

class _MemoryStorage extends TokenStorage {
  @override
  Future<void> saveProfileCompleted(bool value) async {}
}

ProfileSetupController _filledController(ApiException error) {
  return ProfileSetupController(
      _FailingRepository(error),
      SessionService(_MemoryStorage()),
      null,
    )
    ..firstName.text = 'Asha'
    ..lastName.text = 'Rao'
    ..monthlyIncome.text = '50000'
    ..setDob(DateTime(1995, 5, 20));
}

void main() {
  test('user model maps backend json and writes back editable fields', () {
    final user = UserModel.fromJson({
      '_id': 'u1',
      'phone': '9876543210',
      'fullName': 'Asha Rao',
      'dob': '1995-05-20T00:00:00.000Z',
      'pan': 'ABCDE1234F',
      'monthlyIncome': 50000,
      'profileCompleted': true,
      'creditScore': 650,
    });

    expect(user.dob, DateTime(1995, 5, 20));
    expect(user.profileCompleted, isTrue);
    expect(user.toJson(), {
      'fullName': 'Asha Rao',
      'dob': '1995-05-20',
      'pan': 'ABCDE1234F',
      'monthlyIncome': 50000,
    });
  });

  test('api exception exposes per-field validation messages', () {
    const error = ApiException(
      'Validation failed',
      statusCode: 422,
      errors: [
        {'field': 'pan', 'message': 'pan must match the format ABCDE1234F'},
        {'field': 'pan', 'message': 'second message ignored'},
        {'field': 'city', 'message': 'city is too short'},
      ],
    );

    expect(error.fieldErrors, {
      'pan': 'pan must match the format ABCDE1234F',
      'city': 'city is too short',
    });
  });

  test('server error on PAN opens the PAN step and marks the field', () async {
    final controller = _filledController(
      const ApiException(
        'Validation failed',
        statusCode: 422,
        errors: [
          {'field': 'pan', 'message': 'PAN already in use'},
        ],
      ),
    );
    controller.step.value = ProfileSetupController.lastStep;
    controller.pan.text = 'abcde1234f';
    controller.city.text = 'Pune';

    await controller.save();

    expect(controller.step.value, 2);
    expect(controller.serverErrors['pan'], 'PAN already in use');
    expect(controller.isSaving.value, isFalse);
  });

  test('server error without a field shows a general message', () async {
    final controller = _filledController(
      const ApiException('Server is busy', statusCode: 429),
    );
    controller.city.text = 'Pune';

    await controller.save();

    expect(controller.generalError.value, 'Server is busy');
  });
}
