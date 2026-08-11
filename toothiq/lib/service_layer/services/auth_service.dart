import '../../core/api/api_client.dart';
import '../../model/auth_session_model.dart';
import '../../model/user_model.dart';
import '../../utils/phone_validator.dart';

class AuthService {
  final ApiClient _api;

  AuthService(this._api);

  Future<AuthSessionModel> login({
    required String phone,
    required String password,
  }) {
    return _api.login(
      phone: PhoneValidator.normalize(phone),
      password: password,
    );
  }

  Future<AuthSessionModel> register({
    required String name,
    required String phone,
    required String governorateId,
    required String password,
    String? clinicName,
  }) {
    return _api.register(
      name: name,
      phone: PhoneValidator.normalize(phone),
      governorateId: governorateId,
      password: password,
      clinicName: clinicName,
    );
  }

  Future<void> logout() {
    return _api.logout();
  }

  /// مثل قريب: endpoint تحديث توكن الجلسة.
  Future<AuthSessionModel> refresh(String refreshToken) {
    return _api.refresh(refreshToken);
  }

  /// مثل قريب: جلب المستخدم الحالي من التوكن المحفوظ.
  Future<UserModel> me() {
    return _api.getMe();
  }
}
