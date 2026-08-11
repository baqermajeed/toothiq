import 'package:get/get.dart';

import '../controller/app_update_controller.dart';
import '../controller/cart_controller.dart';
import '../controller/main_controller.dart';
import '../controller/session_controller.dart';
import '../core/api/api_client.dart';
import '../service_layer/services/auth_service.dart';
import '../service_layer/services/banner_service.dart';
import '../service_layer/services/brand_service.dart';
import '../service_layer/services/category_service.dart';
import '../service_layer/services/governorate_service.dart';
import '../service_layer/services/driver_tracking_socket_service.dart';
import '../service_layer/services/notification_inbox_service.dart';
import '../service_layer/services/notification_service.dart';
import '../service_layer/services/order_service.dart';
import '../service_layer/services/product_service.dart';
import '../service_layer/services/preferences_storage.dart';
import '../service_layer/services/shop_service.dart';
import '../service_layer/services/token_storage.dart';
import '../service_layer/services/user_service.dart';
import 'home_binding.dart';

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
    Get.put(GovernorateService(Get.find<ApiClient>()), permanent: true);
    Get.put(AuthService(Get.find<ApiClient>()), permanent: true);
    Get.put(UserService(Get.find<ApiClient>()), permanent: true);
    Get.put(NotificationService(), permanent: true);
    if (!Get.isRegistered<NotificationInboxService>()) {
      Get.put(NotificationInboxService(), permanent: true);
    }
    Get.put(
      DriverTrackingSocketService(tokenStorage: Get.find<TokenStorage>()),
      permanent: true,
    );
    Get.put(
      SessionController(
        tokenStorage: Get.find<TokenStorage>(),
        authService: Get.find<AuthService>(),
        userService: Get.find<UserService>(),
        notificationService: Get.find<NotificationService>(),
      ),
      permanent: true,
    );
    Get.put(AppUpdateController(), permanent: true);
    Get.put(BannerService(Get.find<ApiClient>()), permanent: true);
    Get.put(CategoryService(Get.find<ApiClient>()), permanent: true);
    Get.put(BrandService(Get.find<ApiClient>()), permanent: true);
    Get.put(ProductService(Get.find<ApiClient>()), permanent: true);
    Get.put(ShopService(Get.find<ApiClient>()), permanent: true);
    Get.put(OrderService(Get.find<ApiClient>()), permanent: true);
    Get.put(MainController(), permanent: true);

    if (!Get.isRegistered<CartController>()) {
      Get.put(CartController(), permanent: true);
    }

    HomeBinding().dependencies();
  }
}
