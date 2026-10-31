/// What the user picked in the calculator: how much, and for how long.
class LoanTerms {
  const LoanTerms({required this.amount, required this.tenureMonths});

  final int amount;
  final int tenureMonths;
}
