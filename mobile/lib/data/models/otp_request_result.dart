class OtpRequestResult {
  const OtpRequestResult({required this.resendAfterSeconds, this.demoOtp});

  factory OtpRequestResult.fromJson(Object? data) {
    final json = data as Map<String, dynamic>;

    return OtpRequestResult(
      resendAfterSeconds: (json['resendAfterSeconds'] as num).toInt(),
      demoOtp: json['demoOtp'] as String?,
    );
  }

  final int resendAfterSeconds;

  // Only present when the backend runs in demo mode, so testers can see it.
  final String? demoOtp;
}
