import 'package:get/get.dart';

import '../controller/session_controller.dart';
import '../core/api/api_client.dart';
import '../core/api/api_exception.dart';
import '../service_layer/services/auth_service.dart';
import '../service_layer/services/driver_tracking_socket_service.dart';
import '../service_layer/services/order_service.dart';
import '../service_layer/services/preferences_storage.dart';
import '../service_layer/services/product_stock_cache.dart';
import '../service_layer/services/shop_service.dart';
import '../service_layer/services/token_storage.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(PreferencesStorage.instance, permanent: true);
    Get.put(TokenStorage(), permanent: true);
    Get.put(
      ApiClient(
        tokenStorage: Get.find<TokenStorage>(),
        onSessionExpired: () async {
          if (Get.isRegistered<SessionController>()) {
            await Get.find<SessionController>().onSessionExpired();
          }
        },
      ),
      permanent: true,
    );
    Get.put(AuthService(Get.find<ApiClient>()), permanent: true);
    Get.put(OrderService(Get.find<ApiClient>()), permanent: true);
    Get.put(ShopService(Get.find<ApiClient>()), permanent: true);
    Get.put(
      ProductStockCache(Get.find<PreferencesStorage>()),
      permanent: true,
    );
    Get.put(
      DriverTrackingSocketService(tokenStorage: Get.find<TokenStorage>()),
      permanent: true,
    );
    Get.put(
      SessionController(
        tokenStorage: Get.find<TokenStorage>(),
        preferences: Get.find<PreferencesStorage>(),
        authService: Get.find<AuthService>(),
        shopService: Get.find<ShopService>(),
      ),
      permanent: true,
    );
  }
}

String apiErrorMessage(Object error) {
  if (error is ApiException) return error.message;
  return 'حدث خطأ غير متوقع';
}
