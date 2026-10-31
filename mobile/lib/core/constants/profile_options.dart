class ProfileOption {
  const ProfileOption(this.value, this.label);

  // value is what the backend stores; label is what the user sees.
  final String value;
  final String label;
}

class ProfileOptions {
  const ProfileOptions._();

  static const List<ProfileOption> genders = [
    ProfileOption('male', 'Male'),
    ProfileOption('female', 'Female'),
    ProfileOption('other', 'Other'),
  ];

  static const List<ProfileOption> employmentTypes = [
    ProfileOption('salaried', 'Salaried'),
    ProfileOption('self-employed', 'Self-employed'),
  ];

  static String labelFor(List<ProfileOption> options, String? value) {
    for (final option in options) {
      if (option.value == value) {
        return option.label;
      }
    }
    return '-';
  }
}
