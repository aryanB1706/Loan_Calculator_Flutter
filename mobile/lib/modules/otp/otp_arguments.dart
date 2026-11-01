class OtpArguments {
  const OtpArguments({
    required this.phone,
    required this.resendAfterSeconds,
    this.demoOtp,
  });

  final String phone;
  final int resendAfterSeconds;
  final String? demoOtp;
}
