import 'loan_quote.dart';
import 'loan_terms.dart';

/// Eligible terms together with the backend's quote for them.
class LoanOffer {
  const LoanOffer({required this.terms, required this.quote});

  final LoanTerms terms;
  final LoanQuote quote;
}
