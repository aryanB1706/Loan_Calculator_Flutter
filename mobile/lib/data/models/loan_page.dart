import 'loan_application.dart';

/// One page of the "my applications" list.
class LoanPage {
  const LoanPage({
    required this.applications,
    required this.page,
    required this.totalPages,
  });

  factory LoanPage.fromJson(Object? data) {
    final json = data as Map<String, dynamic>;
    final pagination = json['pagination'] as Map<String, dynamic>;

    return LoanPage(
      applications: (json['applications'] as List)
          .map(LoanApplication.fromJson)
          .toList(),
      page: (pagination['page'] as num).toInt(),
      totalPages: (pagination['totalPages'] as num).toInt(),
    );
  }

  final List<LoanApplication> applications;
  final int page;
  final int totalPages;

  bool get hasMore => page < totalPages;
}
