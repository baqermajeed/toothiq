import 'package:get/get.dart';

import '../core/api/api_exception.dart';
import '../model/user_model.dart';
import '../model/user_role.dart';
import '../service_layer/services/auth_service.dart';
import '../service_layer/services/preferences_storage.dart';
import '../service_layer/services/shop_service.dart';
import '../service_layer/services/token_storage.dart';
import '../utils/storage_keys.dart';
import '../view/auth/role_select_page.dart';
import '../view/driver/driver_main_page.dart';
import '../view/shop/shop_main_page.dart';

class SessionController extends GetxController {
  SessionController({
    required TokenStorage tokenStorage,
    required PreferencesStorage preferences,
    required AuthService authService,
    required ShopService shopService,
  }) : _tokenStorage = tokenStorage,
       _preferences = preferences,
       _authService = authService,
       _shopService = shopService;

  final TokenStorage _tokenStorage;
  final PreferencesStorage _preferences;
  final AuthService _authService;
  final ShopService _shopService;

  final isLoading = true.obs;
  final isAuthenticated = false.obs;
  final displayName = ''.obs;
  final shopId = ''.obs;
  final userId = ''.obs;
  final role = Rxn<AppUserRole>();

  @override
  void onInit() {
    super.onInit();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    try {
      final hasToken = await _tokenStorage.hasTokens();
      final savedRole = AppUserRole.fromStorage(
        _preferences.getString(StorageKeys.selectedRole),
      );
      shopId.value = _preferences.getString(StorageKeys.shopId) ?? '';
      userId.value = _preferences.getString(StorageKeys.userId) ?? '';
      displayName.value = _preferences.getString(StorageKeys.displayName) ?? '';

      if (!hasToken || savedRole == null) {
        isAuthenticated.value = false;
        return;
      }

      final user = await _authService.me();
      if (!_roleMatches(user, savedRole)) {
        await _clearLocalSession();
        return;
      }

      await _applyUser(user, savedRole);
      isAuthenticated.value = true;
    } catch (_) {
      await _clearLocalSession();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> login({
    required String phone,
    required String password,
    required AppUserRole selectedRole,
  }) async {
    final session = await _authService.login(phone: phone, password: password);
    await _tokenStorage.saveTokens(session.accessToken, session.refreshToken);

    final user = session.user.partnerRole != null
        ? session.user
        : await _authService.me();

    if (!_roleMatches(user, selectedRole)) {
      await _tokenStorage.clearTokens();
      throw ApiException(
        'هذا الحساب ليس ${selectedRole.label}. استخدم الحساب المناسب.',
      );
    }

    await selectRole(selectedRole);
    await _applyUser(user, selectedRole);
    isAuthenticated.value = true;
  }

  Future<void> selectRole(AppUserRole selected) async {
    role.value = selected;
    await _preferences.setString(StorageKeys.selectedRole, selected.apiValue);
  }

  Future<void> _applyUser(UserModel user, AppUserRole selectedRole) async {
    role.value = selectedRole;
    displayName.value = user.name;
    userId.value = user.id;
    await _preferences.setString(StorageKeys.displayName, user.name);
    await _preferences.setString(StorageKeys.userId, user.id);

    if (selectedRole == AppUserRole.shop) {
      final resolvedShopId =
          user.shopId ?? await _shopService.resolveShopId(user);
      if (resolvedShopId == null || resolvedShopId.isEmpty) {
        throw const ApiException('لم يتم ربط حسابك بمتجر. تواصل مع الإدارة.');
      }
      shopId.value = resolvedShopId;
      await _preferences.setString(StorageKeys.shopId, resolvedShopId);
    } else {
      shopId.value = '';
      await _preferences.remove(StorageKeys.shopId);
    }
  }

  bool _roleMatches(UserModel user, AppUserRole selected) {
    final apiRole = user.partnerRole;
    if (apiRole != null) return apiRole == selected;
    return true;
  }

  Future<void> updateDisplayName(String name) async {
    displayName.value = name;
    await _preferences.setString(StorageKeys.displayName, name);
  }

  void openHomeForRole() {
    final current = role.value;
    if (current == AppUserRole.driver) {
      DriverMainPage.open();
    } else {
      ShopMainPage.open();
    }
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
    } catch (_) {}
    await _clearLocalSession();
    Get.offAll(() => const RoleSelectPage());
  }

  Future<void> _clearLocalSession() async {
    await _tokenStorage.clearTokens();
    await _preferences.remove(StorageKeys.selectedRole);
    await _preferences.remove(StorageKeys.displayName);
    await _preferences.remove(StorageKeys.shopId);
    await _preferences.remove(StorageKeys.userId);
    isAuthenticated.value = false;
    role.value = null;
    displayName.value = '';
    shopId.value = '';
    userId.value = '';
  }

  Future<void> onSessionExpired() async => logout();
}
