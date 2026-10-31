class LoanQuote {
  const LoanQuote({
    required this.emi,
    required this.totalPayable,
    required this.totalInterest,
    required this.interestRate,
  });

  factory LoanQuote.fromJson(Object? data) {
    final json = data as Map<String, dynamic>;

    return LoanQuote(
      emi: json['emi'] as num,
      totalPayable: json['totalPayable'] as num,
      totalInterest: json['totalInterest'] as num,
      interestRate: json['interestRate'] as num,
    );
  }

  final num emi;
  final num totalPayable;
  final num totalInterest;

  // Annual interest rate in percent, as used by the backend for this quote.
  final num interestRate;
}
