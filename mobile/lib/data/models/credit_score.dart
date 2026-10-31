class CreditScore {
  const CreditScore({required this.score, required this.band});

  factory CreditScore.fromJson(Object? data) {
    final json = data as Map<String, dynamic>;

    return CreditScore(
      score: (json['score'] as num).toInt(),
      band: json['band'] as String,
    );
  }

  final int score;

  // poor | fair | good | excellent, decided by the backend.
  final String band;
}
