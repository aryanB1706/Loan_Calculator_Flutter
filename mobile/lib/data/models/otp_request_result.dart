class OtpRequestResult {
  const OtpRequestResult({required this.resendAfterSeconds});

  factory OtpRequestResult.fromJson(Object? data) {
    final json = data as Map<String, dynamic>;

    return OtpRequestResult(
      resendAfterSeconds: (json['resendAfterSeconds'] as num).toInt(),
    );
  }

  final int resendAfterSeconds;
}
