import 'package:get/get.dart';

import '../service_layer/services/get_storage_service.dart';
import '../utils/storage_keys.dart';

class SessionController extends GetxController {
  final RxnString token = RxnString();
  final GetStorageService _storage = GetStorageService();

  @override
  void onInit() {
    super.onInit();
    final saved = _storage.read<String>(StorageKeys.authToken);
    if ((saved ?? '').isNotEmpty) {
      token.value = saved;
    }
  }

  void setToken(String? value) {
    token.value = value;
    if ((value ?? '').isNotEmpty) {
      _storage.write(StorageKeys.authToken, value);
    } else {
      _storage.remove(StorageKeys.authToken);
    }
  }

  void clearSession() {
    setToken(null);
  }

  bool get isAuthenticated => (token.value ?? '').isNotEmpty;
}
