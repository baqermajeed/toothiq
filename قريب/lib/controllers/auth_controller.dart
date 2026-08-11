import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'categories_controller.dart';
import 'home_products_controller.dart';
import 'home_shops_controller.dart';
import 'orders_controller.dart';
import '../core/errors/api_exception.dart';
import '../models/user.dart';
import '../widgets/common/app_toast.dart';
import '../services/api_client.dart';
import '../services/notification_service.dart';
import '../services/token_storage.dart';

/// حالة المصادقة؛ عند انتهاء الجلسة (401) يُمسَح المستخدم بدون رسالة.
/// GetX Controller مع obs/Obx.
class AuthController extends GetxController {
  AuthController({required TokenStorage tokenStorage}) : _tokenStorage = tokenStorage {
    _apiClient = ApiClient(
      tokenStorage: _tokenStorage,
      onSessionExpired: _onSessionExpired,
    );
  }

  late ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  final Rxn<User> user = Rxn<User>();
  final RxBool isLoading = true.obs;
  final Rxn<String> errorMessage = Rxn<String>();

  bool get isAuthenticated => user.value != null;

  ApiClient get apiClient => _apiClient;

  void _onSessionExpired() {
    user.value = null;
    errorMessage.value = null;
  }

  Future<void> loadStoredAuth() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final hasTokens = await _tokenStorage.hasTokens();
      if (!hasTokens) {
        user.value = null;
        isLoading.value = false;
        return;
      }
      final me = await _apiClient.getMe();
      if (me != null) {
        user.value = me;
        _syncFcmToken();
      } else {
        await _tokenStorage.clearTokens();
        user.value = null;
      }
      isLoading.value = false;
    } catch (_) {
      await _tokenStorage.clearTokens();
      user.value = null;
      isLoading.value = false;
    }
  }

  Future<bool> login(
    String phone,
    String password, {
    List<double>? location,
  }) async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final result = await _apiClient.login(phone, password, location: location);
      await _tokenStorage.saveTokens(result.accessToken, result.refreshToken);
      user.value = result.user;
      refreshDataAfterAuth();
      _syncFcmToken();
      isLoading.value = false;
      return true;
    } on ApiException catch (e) {
      debugPrint('[Login] رد السيرفر: statusCode=${e.statusCode}, code=${e.code}, message=${e.message}');
      errorMessage.value = e.message;
      isLoading.value = false;
      return false;
    } catch (e, st) {
      debugPrint('[Login] خطأ: $e');
      debugPrint('[Login] stackTrace: $st');
      errorMessage.value = 'حدث خطأ، حاول مرة أخرى';
      isLoading.value = false;
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String phone,
    required String password,
    String role = 'customer',
    List<double>? location,
  }) async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final body = <String, dynamic>{
        'name': name,
        'phone': phone,
        'password': password,
        'role': role,
      };
      if (location != null && location.length >= 2) {
        body['location'] = {
          'type': 'Point',
          'coordinates': [location[0], location[1]],
        };
      }
      final result = await _apiClient.register(body);
      await _tokenStorage.saveTokens(result.accessToken, result.refreshToken);
      user.value = result.user;
      refreshDataAfterAuth();
      _syncFcmToken();
      isLoading.value = false;
      return true;
    } on ApiException catch (e) {
      errorMessage.value = e.message;
      isLoading.value = false;
      return false;
    } catch (_) {
      errorMessage.value = 'حدث خطأ، حاول مرة أخرى';
      isLoading.value = false;
      return false;
    }
  }

  /// تسجيل ضيف: اسم + رقم فقط، يُولّد الرمز تلقائياً.
  /// يُحفظ التوكنات ويُحدّث [user] فوراً — أي تسجيل دخول تلقائي للضيف.
  /// يُرجع (phone, generatedCode) للعرض بعد الطلب، أو null عند الفشل.
  Future<({String phone, String code})?> guestRegister({
    required String name,
    required String phone,
    List<double>? location,
  }) async {
    errorMessage.value = null;
    try {
      final body = <String, dynamic>{'name': name, 'phone': phone};
      if (location != null && location.length >= 2) {
        body['location'] = {
          'type': 'Point',
          'coordinates': [location[0], location[1]],
        };
      }
      final result = await _apiClient.guestRegister(body);
      // تسجيل دخول تلقائي: حفظ التوكنات وتحديث المستخدم حتى يبقى الضيف مسجّلاً دون الحاجة لتسجيل دخول يدوي.
      await _tokenStorage.saveTokens(result.accessToken, result.refreshToken);
      user.value = result.user;
      refreshDataAfterAuth();
      _syncFcmToken();
      final code = result.generatedCode ?? '';
      return (phone: result.user.phone, code: code);
    } on ApiException catch (e) {
      errorMessage.value = e.message;
      return null;
    } catch (_) {
      errorMessage.value = 'حدث خطأ، حاول مرة أخرى';
      return null;
    }
  }

  Future<void> logout() async {
    if (Get.isRegistered<NotificationService>()) {
      final notif = Get.find<NotificationService>();
      await notif.unsubscribeFromTopics();
      await _apiClient.updateFcmToken(null);
    }
    await _tokenStorage.clearTokens();
    user.value = null;
    errorMessage.value = null;
  }

  /// مزامنة توكن FCM مع الـ API والاشتراك في المواضيع.
  Future<void> _syncFcmToken() async {
    if (!Get.isRegistered<NotificationService>()) return;
    try {
      final notif = Get.find<NotificationService>();
      await notif.initialize();
      final token = await notif.getToken();
      if (token != null && token.isNotEmpty) {
        await _apiClient.updateFcmToken(token);
      }
      await notif.subscribeToTopics();
    } catch (_) {
      // لا نفشل التطبيق
    }
  }

  void clearError() {
    errorMessage.value = null;
  }

  /// تحديث موقع التوصيل فقط (من البطاقة الترحيبية أو أي مكان) ثم إعادة تحميل المحلات والمنتجات.
  /// [silent] عند true لا يُعرض توست (مثل التحديث التلقائي عند فتح التطبيق).
  Future<void> updateDeliveryLocation(double lat, double lng, {bool silent = false}) async {
    final current = user.value;
    if (current == null || !isAuthenticated) return;
    try {
      final updated = await _apiClient.updateMe(
        name: current.name,
        location: [lng, lat],
      );
      user.value = updated;
      await _refreshLocationDependentData();
    } on ApiException catch (e) {
      if (!silent) AppToast.show('فشل الحفظ', e.message, type: ToastType.error);
    } catch (_) {
      if (!silent) AppToast.show('فشل الحفظ', 'حدث خطأ، حاول مرة أخرى', type: ToastType.error);
    }
  }

  /// إعادة تحميل المحلات والمنتجات حسب الموقع الجديد.
  /// ننتظر تحميل المحلات أولاً ثم المنتجات لتجنّب عرض منتجات قديمة أو عدم ظهورها.
  Future<void> _refreshLocationDependentData() async {
    if (Get.isRegistered<HomeShopsController>()) {
      await Get.find<HomeShopsController>().loadShops();
    }
    if (Get.isRegistered<HomeProductsController>()) {
      await Get.find<HomeProductsController>().loadProducts();
    }
    if (Get.isRegistered<CategoriesController>()) {
      await Get.find<CategoriesController>().loadShopsBySelectedCategory();
    }
  }

  /// تحديث البيانات المعتمدة على المستخدم بعد تسجيل الدخول أو التسجيل.
  void refreshDataAfterAuth() {
    _refreshLocationDependentData(); // تشغيل في الخلفية
    if (Get.isRegistered<OrdersController>()) {
      Get.find<OrdersController>().loadOrders();
    }
  }
}
