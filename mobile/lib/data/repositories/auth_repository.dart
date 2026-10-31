import '../../core/network/api_client.dart';
import '../models/auth_session.dart';
import '../models/otp_request_result.dart';

class AuthRepository {
  const AuthRepository(this._api);

  final ApiClient _api;

  Future<OtpRequestResult> sendOtp(String phone) async {
    final response = await _api.post<OtpRequestResult>(
      '/auth/send-otp',
      data: {'phone': phone},
      parser: OtpRequestResult.fromJson,
    );
    return response.data!;
  }

  Future<AuthSession> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    final response = await _api.post<AuthSession>(
      '/auth/verify-otp',
      data: {'phone': phone, 'otp': otp},
      parser: AuthSession.fromJson,
    );
    return response.data!;
  }

  Future<void> logout() async {
    await _api.post<void>('/auth/logout');
  }
}
