class UserModel {
  const UserModel({
    this.id = '',
    this.phone = '',
    this.fullName,
    this.dob,
    this.gender,
    this.pan,
    this.email,
    this.monthlyIncome,
    this.employmentType,
    this.city,
    this.profileCompleted = false,
    this.creditScore,
  });

  factory UserModel.fromJson(Object? data) {
    final json = data as Map<String, dynamic>;

    return UserModel(
      id: json['_id'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      fullName: json['fullName'] as String?,
      dob: _parseDate(json['dob']),
      gender: json['gender'] as String?,
      pan: json['pan'] as String?,
      email: json['email'] as String?,
      monthlyIncome: json['monthlyIncome'] as num?,
      employmentType: json['employmentType'] as String?,
      city: json['city'] as String?,
      profileCompleted: json['profileCompleted'] == true,
      creditScore: (json['creditScore'] as num?)?.toInt(),
    );
  }

  final String id;
  final String phone;
  final String? fullName;
  final DateTime? dob;
  final String? gender;
  final String? pan;
  final String? email;
  final num? monthlyIncome;
  final String? employmentType;
  final String? city;
  final bool profileCompleted;
  final int? creditScore;

  // Only the fields the user can edit, in the shape PUT /users/me accepts.
  // Server-owned fields (id, phone, score, completion flag) are left out.
  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'dob': dob == null ? null : _formatDate(dob!),
      'gender': gender,
      'pan': pan,
      'email': email,
      'monthlyIncome': monthlyIncome,
      'employmentType': employmentType,
      'city': city,
    }..removeWhere((_, value) => value == null);
  }

  // The backend stores dob as UTC midnight; reading the UTC parts keeps the
  // same calendar day in every timezone.
  static DateTime? _parseDate(Object? value) {
    if (value is! String) {
      return null;
    }
    final utc = DateTime.parse(value).toUtc();
    return DateTime(utc.year, utc.month, utc.day);
  }

  static String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}
