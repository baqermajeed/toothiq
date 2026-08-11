import 'user_model.dart';

class AuthSessionModel {
  final UserModel user;
  final String accessToken;
  final String refreshToken;

  const AuthSessionModel({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthSessionModel.fromJson(dynamic json) {
    final map = json as Map<String, dynamic>;
    return AuthSessionModel(
      user: UserModel.fromJson(map['user'] as Map<String, dynamic>),
      accessToken: map['accessToken']?.toString() ?? '',
      refreshToken: map['refreshToken']?.toString() ?? '',
    );
  }
}
