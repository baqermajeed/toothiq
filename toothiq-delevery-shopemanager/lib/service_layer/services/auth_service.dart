import '../../core/api/api_client.dart';
import '../../core/utils/phone_validator.dart';
import '../../model/auth_session_model.dart';
import '../../model/user_model.dart';

class AuthService {
  AuthService(this._api);

  final ApiClient _api;

  Future<AuthSessionModel> login({
    required String phone,
    required String password,
  }) {
    return _api.login(
      phone: PhoneValidator.normalize(phone),
      password: password,
    );
  }

  Future<void> logout() => _api.logout();

  Future<UserModel> me() => _api.getMe();
}
