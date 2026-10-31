import '../../core/network/api_client.dart';
import '../models/eligibility_result.dart';
import '../models/loan_application.dart';
import '../models/loan_page.dart';
import '../models/loan_quote.dart';
import '../models/loan_terms.dart';
import '../models/repayment.dart';

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

  Future<EligibilityResult> checkEligibility(LoanTerms terms) async {
    final response = await _api.post<EligibilityResult>(
      '/loans/eligibility',
      data: _termsJson(terms),
      parser: EligibilityResult.fromJson,
    );
    return response.data!;
  }

  Future<LoanApplication> apply(
    LoanTerms terms, {
    required String purpose,
  }) async {
    final response = await _api.post<LoanApplication>(
      '/loans/apply',
      data: {..._termsJson(terms), 'purpose': purpose},
      parser: _parseApplication,
    );
    return response.data!;
  }

  // Applications come newest first.
  Future<LoanPage> listApplications({int page = 1, int limit = 10}) async {
    final response = await _api.get<LoanPage>(
      '/loans',
      queryParameters: {'page': page, 'limit': limit},
      parser: LoanPage.fromJson,
    );
    return response.data!;
  }

  Future<LoanApplication?> latestApplication() async {
    final page = await listApplications(limit: 1);
    return page.applications.isEmpty ? null : page.applications.first;
  }

  Future<LoanApplication> getApplication(String id) async {
    final response = await _api.get<LoanApplication>(
      '/loans/$id',
      parser: _parseApplication,
    );
    return response.data!;
  }

  // Only available once the loan is disbursed.
  Future<List<Repayment>> repayments(String loanId) async {
    final response = await _api.get<List<Repayment>>(
      '/loans/$loanId/repayments',
      parser: (data) {
        final list = (data as Map<String, dynamic>)['repayments'] as List;
        return list.map(Repayment.fromJson).toList();
      },
    );
    return response.data!;
  }

  Future<PaymentResult> payInstallment(
    String loanId,
    int installmentNumber,
  ) async {
    final response = await _api.post<PaymentResult>(
      '/loans/$loanId/repayments/$installmentNumber/pay',
      parser: PaymentResult.fromJson,
    );
    return response.data!;
  }

  static Map<String, int> _termsJson(LoanTerms terms) {
    return {'amount': terms.amount, 'tenureMonths': terms.tenureMonths};
  }

  static LoanApplication _parseApplication(Object? data) {
    return LoanApplication.fromJson(
      (data as Map<String, dynamic>)['application'],
    );
  }
}
