import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:loan_app/core/network/api_client.dart';
import 'package:loan_app/core/network/api_exception.dart';
import 'package:loan_app/data/models/credit_score.dart';
import 'package:loan_app/data/models/loan_application.dart';
import 'package:loan_app/data/models/user_model.dart';
import 'package:loan_app/data/repositories/loan_repository.dart';
import 'package:loan_app/data/repositories/user_repository.dart';
import 'package:loan_app/modules/home/home_controller.dart';

class _NoApi implements ApiClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeUsers extends UserRepository {
  _FakeUsers() : super(_NoApi());

  // Set to make every call fail, like a phone with no connection.
  ApiException? failure;

  @override
  Future<UserModel> getMe() async {
    if (failure != null) throw failure!;
    return const UserModel(fullName: 'Asha Verma');
  }

  @override
  Future<CreditScore> getCreditScore() async {
    if (failure != null) throw failure!;
    return const CreditScore(score: 720, band: 'good');
  }
}

class _FakeLoans extends LoanRepository {
  _FakeLoans() : super(_NoApi());

  @override
  Future<LoanApplication?> latestApplication() async => null;
}

void main() {
  tearDown(Get.reset);

  test('shows an offline error, then recovers when retry succeeds', () async {
    final users = _FakeUsers()
      ..failure = const ApiException('No connection', isNetworkError: true);
    final controller = HomeController(users, _FakeLoans());

    await controller.load();

    expect(controller.isLoading.value, isFalse);
    expect(controller.errorMessage.value, 'No connection');
    expect(controller.isOffline.value, isTrue);
    expect(controller.creditScore.value, isNull);

    users.failure = null;
    final retrying = controller.retry();

    // Retry brings the loader back instead of leaving the error on screen.
    expect(controller.isLoading.value, isTrue);
    await retrying;

    expect(controller.isLoading.value, isFalse);
    expect(controller.errorMessage.value, isNull);
    expect(controller.isOffline.value, isFalse);
    expect(controller.firstName, 'Asha');
    expect(controller.creditScore.value?.score, 720);
  });

  test('a server error is not reported as offline', () async {
    final users = _FakeUsers()
      ..failure = const ApiException('Server down', statusCode: 500);
    final controller = HomeController(users, _FakeLoans());

    await controller.load();

    expect(controller.errorMessage.value, 'Server down');
    expect(controller.isOffline.value, isFalse);
  });
}
