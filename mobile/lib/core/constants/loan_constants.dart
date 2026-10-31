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

class LoanPurposes {
  const LoanPurposes._();

  // The backend accepts any text of 3-200 characters; a fixed list keeps the
  // data clean and the picker simple.
  static const List<String> options = [
    'Personal expenses',
    'Medical emergency',
    'Education',
    'Home renovation',
    'Travel',
    'Business',
    'Wedding',
    'Other',
  ];
}
