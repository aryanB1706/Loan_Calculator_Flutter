class Validators {
  const Validators._();

  static const int minAge = 18;

  // Same rule as the backend: 10 digits, first digit 6-9.
  static final RegExp _indianMobile = RegExp(r'^[6-9]\d{9}$');
  static final RegExp _pan = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$');
  static final RegExp _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

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

  static String? name(String? value, {required String label}) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Please enter your $label';
    }
    if (text.length > 50) {
      return '$label is too long';
    }
    return null;
  }

  static String? email(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Please enter your email ID';
    }
    return _email.hasMatch(text) ? null : 'Enter a valid email ID';
  }

  static String? pan(String? value) {
    final text = value?.trim().toUpperCase() ?? '';

    if (text.isEmpty) {
      return 'Please enter your PAN number';
    }
    return _pan.hasMatch(text) ? null : 'PAN must look like ABCDE1234F';
  }

  static String? monthlyIncome(String? value) {
    final amount = num.tryParse(value?.trim() ?? '');

    if (amount == null) {
      return 'Please enter your monthly income';
    }
    return amount > 0 ? null : 'Income must be greater than 0';
  }

  static String? city(String? value) {
    final text = value?.trim() ?? '';

    if (text.length < 2) {
      return 'Please enter your city';
    }
    return text.length > 100 ? 'City name is too long' : null;
  }

  static String? required(Object? value, {required String label}) {
    return value == null ? 'Please select your $label' : null;
  }

  static String? dateOfBirth(DateTime? dob, {DateTime? today}) {
    if (dob == null) {
      return 'Please select your date of birth';
    }
    return ageOn(dob, today ?? DateTime.now()) >= minAge
        ? null
        : 'You must be at least $minAge years old';
  }

  static int ageOn(DateTime dob, DateTime today) {
    final hadBirthday =
        today.month > dob.month ||
        (today.month == dob.month && today.day >= dob.day);
    return today.year - dob.year - (hadBirthday ? 0 : 1);
  }
}
