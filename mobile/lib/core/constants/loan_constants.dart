/// Mirrors backend/src/constants/loanRules.js. The backend re-validates
/// everything, so these limits only shape the sliders and inputs.
class LoanLimits {
  const LoanLimits._();

  static const int minAmount = 10000;
  static const int maxAmount = 500000;
  static const int amountStep = 1000;
  static const int defaultAmount = 50000;

  static const int minTenureMonths = 3;
  static const int maxTenureMonths = 60;
  static const int defaultTenureMonths = 12;

  static int get amountDivisions => (maxAmount - minAmount) ~/ amountStep;
  static int get tenureDivisions => maxTenureMonths - minTenureMonths;
}
