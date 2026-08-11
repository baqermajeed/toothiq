import 'package:get/get.dart';

import '../model/auth_session_model.dart';
import '../model/user_model.dart';
import '../service_layer/services/app_data_refresh_service.dart';
import '../service_layer/services/auth_service.dart';
import '../service_layer/services/notification_service.dart';
import '../service_layer/services/token_storage.dart';
import '../service_layer/services/user_service.dart';
import '../service_layer/services/user_session_service.dart';

/// حالة الجلسة — نفس تدفق قريب: توكنات آمنة + مستخدم من API + تحميل عند الإقلاع.
class SessionController extends GetxController {
  SessionController({
    required TokenStorage tokenStorage,
    required AuthService authService,
    required UserService userService,
    required NotificationService notificationService,
  }) : _tokenStorage = tokenStorage,
       _authService = authService,
       _userService = userService,
       _notificationService = notificationService;

  final TokenStorage _tokenStorage;
  final AuthService _authService;
  final UserService _userService;
  final NotificationService _notificationService;

  final user = Rxn<UserModel>();
  final isLoading = true.obs;

  bool get isAuthenticated => user.value != null;

  @override
  void onInit() {
    super.onInit();
    loadStoredAuth();
  }

  Future<void> loadStoredAuth() async {
    isLoading.value = true;
    try {
      final hasTokens = await _tokenStorage.hasTokens();
      if (!hasTokens) {
        user.value = null;
        await UserSessionService.onSignedOut();
        return;
      }
      try {
        final me = await _authService.me();
        user.value = me;
        await UserSessionService.onSignedIn(me);
        await _postAuthSync();
      } catch (_) {
        await _tokenStorage.clearTokens();
        user.value = null;
        await UserSessionService.onSignedOut();
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> setSession(AuthSessionModel session) async {
    await _tokenStorage.saveTokens(session.accessToken, session.refreshToken);
    user.value = session.user;
    await UserSessionService.onSignedIn(session.user);
    await _postAuthSync();
  }

  Future<void> setTokens({
    required String accessToken,
    required String refreshToken,
    UserModel? user,
  }) async {
    await _tokenStorage.saveTokens(accessToken, refreshToken);
    if (user != null) {
      this.user.value = user;
      await UserSessionService.onSignedIn(user);
      await _postAuthSync();
    }
  }

  Future<void> clearSession() async {
    await _clearFcmToken();
    user.value = null;
    await _tokenStorage.clearTokens();
    await UserSessionService.onSignedOut();
  }

  Future<void> onSessionExpired() async {
    user.value = null;
    await UserSessionService.onSignedOut();
  }

  /// للتوافق مع الاستدعاءات القديمة.
  Future<void> hydrateFromStorage() => loadStoredAuth();

  Future<void> _postAuthSync() async {
    AppDataRefreshService.refreshAfterAuth();
    await _syncFcmToken();
  }

  Future<void> _syncFcmToken() async {
    if (!isAuthenticated) return;
    try {
      await _notificationService.initialize();
      final token = await _notificationService.getToken();
      if (token != null && token.isNotEmpty) {
        await _userService.updateFcmToken(token);
      }
      await _notificationService.subscribeToTopics();
      _notificationService.onTokenRefresh(_userService.updateFcmToken);
    } catch (_) {
      // لا نفشل التطبيق
    }
  }

  Future<void> _clearFcmToken() async {
    try {
      await _notificationService.unsubscribeFromTopics();
      await _userService.updateFcmToken(null);
    } catch (_) {
      // لا نفشل التطبيق
    }
  }
}
