class EligibilityResult {
  const EligibilityResult({
    required this.eligible,
    required this.maxEligibleAmount,
    required this.reasons,
  });

  factory EligibilityResult.fromJson(Object? data) {
    final json = data as Map<String, dynamic>;

    return EligibilityResult(
      eligible: json['eligible'] == true,
      maxEligibleAmount: json['maxEligibleAmount'] as num,
      reasons: (json['reasons'] as List).cast<String>(),
    );
  }

  final bool eligible;
  final num maxEligibleAmount;

  // Plain-language explanations written by the backend; empty when eligible.
  final List<String> reasons;
}
