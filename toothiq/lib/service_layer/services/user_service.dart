import '../../model/user_model.dart';
import '../../core/api/api_client.dart';

class UserService {
  final ApiClient _api;

  UserService(this._api);

  Future<UserModel> getCurrentUser() {
    return _api.getMe();
  }

  Future<UserModel> updateCurrentUser({
    String? name,
    String? phone,
    String? clinicName,
    List<double>? location,
  }) {
    return _api.updateMe(
      name: name,
      phone: phone,
      clinicName: clinicName,
      location: location,
    );
  }

  Future<UserModel> updateLocation(double lat, double lng) {
    return _api.updateMe(location: [lng, lat]);
  }

  Future<void> updateFcmToken(String? token) {
    return _api.updateFcmToken(token);
  }
}
