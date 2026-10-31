class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.profileCompleted,
  });

  factory AuthSession.fromJson(Object? data) {
    final json = data as Map<String, dynamic>;

    return AuthSession(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      profileCompleted: json['profileCompleted'] == true,
    );
  }

  final String accessToken;
  final String refreshToken;
  final bool profileCompleted;
}
