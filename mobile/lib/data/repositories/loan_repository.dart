import '../../core/network/api_client.dart';
import '../models/loan_application.dart';
import '../models/loan_quote.dart';

class LoanRepository {
  const LoanRepository(this._api);

  final ApiClient _api;

  // The EMI maths lives only on the backend so the app never disagrees with it.
  Future<LoanQuote> calculate({
    required int amount,
    required int tenureMonths,
  }) async {
    final response = await _api.post<LoanQuote>(
      '/loans/calculate',
      data: {'amount': amount, 'tenureMonths': tenureMonths},
      parser: LoanQuote.fromJson,
    );
    return response.data!;
  }

  // Applications come newest first, so asking for one gives the latest.
  Future<LoanApplication?> latestApplication() async {
    final response = await _api.get<List<LoanApplication>>(
      '/loans',
      queryParameters: {'page': 1, 'limit': 1},
      parser: _parseApplications,
    );
    final applications = response.data!;
    return applications.isEmpty ? null : applications.first;
  }

  static List<LoanApplication> _parseApplications(Object? data) {
    final list = (data as Map<String, dynamic>)['applications'] as List;
    return list.map(LoanApplication.fromJson).toList();
  }
}
