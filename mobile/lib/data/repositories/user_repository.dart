import '../../core/network/api_client.dart';
import '../models/credit_score.dart';
import '../models/user_model.dart';

class UserRepository {
  const UserRepository(this._api);

  final ApiClient _api;

  Future<UserModel> getMe() async {
    final response = await _api.get<UserModel>('/users/me', parser: _parseUser);
    return response.data!;
  }

  Future<UserModel> updateMe(UserModel profile) async {
    final response = await _api.put<UserModel>(
      '/users/me',
      data: profile.toJson(),
      parser: _parseUser,
    );
    return response.data!;
  }

  Future<CreditScore> getCreditScore() async {
    final response = await _api.get<CreditScore>(
      '/users/me/credit-score',
      parser: CreditScore.fromJson,
    );
    return response.data!;
  }

  static UserModel _parseUser(Object? data) {
    return UserModel.fromJson((data as Map<String, dynamic>)['user']);
  }
}
