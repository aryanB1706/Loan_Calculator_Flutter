class Validators {
  const Validators._();

  // Same rule as the backend: 10 digits, first digit 6-9.
  static final RegExp _indianMobile = RegExp(r'^[6-9]\d{9}$');

  static String? mobileNumber(String? value) {
    final phone = value?.trim() ?? '';

    if (phone.isEmpty) {
      return 'Please enter your mobile number';
    }
    if (!_indianMobile.hasMatch(phone)) {
      return 'Enter a valid 10-digit mobile number';
    }
    return null;
  }
}
