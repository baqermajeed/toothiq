import 'user.dart';

/// نتيجة تسجيل الدخول أو التسجيل أو تجديد التوكن.
class AuthResult {
  const AuthResult({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    this.expiresIn,
    this.generatedCode,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return AuthResult(
      user: User.fromJson(data['user'] as Map<String, dynamic>),
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
      expiresIn: data['expiresIn'] as String?,
      generatedCode: data['generatedCode'] as String?,
    );
  }

  final User user;
  final String accessToken;
  final String refreshToken;
  final String? expiresIn;
  final String? generatedCode;
}
