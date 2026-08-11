import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_options.dart';
import 'services/local_notifications_service.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'core/theme/app_theme.dart';
import 'controllers/app_location_controller.dart';
import 'controllers/all_shops_controller.dart';
import 'controllers/auth_controller.dart';
import 'controllers/location_on_open_controller.dart';
import 'controllers/cart_controller.dart';
import 'controllers/edit_profile_controller.dart';
import 'controllers/categories_controller.dart';
import 'controllers/home_products_controller.dart';
import 'controllers/home_shops_controller.dart';
import 'controllers/location_gate_controller.dart';
import 'controllers/location_required_controller.dart';
import 'controllers/login_controller.dart';
import 'controllers/main_shell_controller.dart';
import 'controllers/order_detail_controller.dart';
import 'controllers/orders_controller.dart';
import 'controllers/product_detail_controller.dart';
import 'controllers/register_controller.dart';
import 'controllers/search_products_controller.dart';
import 'controllers/shop_products_controller.dart';
import 'controllers/theme_controller.dart';
import 'controllers/voice_order_controller.dart';
import 'controllers/app_update_controller.dart';
import 'controllers/contact_info_controller.dart';
import 'screens/auth/location_gate_screen.dart';
import 'screens/auth/location_required_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/cart/cart_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/product/product_detail_screen.dart';
import 'controllers/full_screen_map_controller.dart';
import 'screens/map/full_screen_map_screen.dart';
import 'screens/orders/order_detail_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/profile/static_content_screen.dart';
import 'screens/all_shops/all_shops_screen.dart';
import 'screens/search/search_results_screen.dart';
import 'screens/shop_products/shop_products_screen.dart';
import 'screens/voice_order/voice_order_screen.dart';
import 'widgets/common/loading/full_page_loading.dart';
import 'widgets/shell/main_shell.dart';
import 'services/driver_tracking_socket_service.dart';
import 'services/notification_service.dart';
import 'services/token_storage.dart';

void main() {
  // التقاط الأخطاء غير المعالجة (مفيد لتتبع تجمّد الخريطة على iOS)
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await _runApp();
  }, (Object error, StackTrace stack) {
    if (kDebugMode) {
      print('[MAP_DEBUG] UNCAUGHT ERROR: $error');
      print('[MAP_DEBUG] STACK: $stack');
    }
    FlutterError.reportError(
      FlutterErrorDetails(exception: error, stack: stack),
    );
  });
}

void _navigateFromNotification(RemoteMessage message) {
  final data = message.data;
  final type = data['type'] as String?;
  final orderId = data['orderId'] as String?;
  if ((type == 'order_on_the_way' || type == 'new_order') &&
      orderId != null &&
      orderId.isNotEmpty) {
    Get.toNamed('/order-detail', arguments: orderId);
  }
}

void _navigateFromNotificationPayload(String? type, String? orderId) {
  if ((type == 'order_on_the_way' || type == 'new_order') &&
      orderId != null &&
      orderId.isNotEmpty) {
    Get.toNamed('/order-detail', arguments: orderId);
  }
}

Future<void> _requestIosNotificationPermission() async {
  // طلب صلاحيات الإشعارات على iOS
  final settings = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    provisional: false,
  );

  // ضمان ظهور الإشعارات عندما يكون التطبيق في الواجهة على iOS
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  if (kDebugMode) {
    print('[NOTIFICATIONS] iOS permission status: ${settings.authorizationStatus}');
  }
}

Future<void> _logFcmToken() async {
  try {
    final token = await FirebaseMessaging.instance.getToken();
    if (kDebugMode) {
      print('[NOTIFICATIONS] FCM Token: $token');
    }
  } catch (e, st) {
    if (kDebugMode) {
      print('[NOTIFICATIONS] Error while getting FCM token: $e');
      print('[NOTIFICATIONS] STACK: $st');
    }
  }
}

void _setupNotificationTapHandling(LocalNotificationsService localNotifications) {
  localNotifications.onNotificationTap = _navigateFromNotificationPayload;

  FirebaseMessaging.instance.getInitialMessage().then((message) {
    if (message != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateFromNotification(message);
      });
    }
  });
  FirebaseMessaging.onMessageOpenedApp.listen(_navigateFromNotification);
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final data = message.data;
    final type = data['type'] as String?;
    final orderId = data['orderId'] as String?;
    if ((type == 'order_on_the_way' || type == 'new_order') &&
        orderId != null &&
        orderId.isNotEmpty) {
      localNotifications.showNotification(
        title: message.notification?.title ?? 'إشعار',
        body: message.notification?.body ?? '',
        payload: jsonEncode({'type': type, 'orderId': orderId}),
      );
    }
  });
}

Future<void> _runApp() async {
  final tokenStorage = TokenStorage();
  Get.put(tokenStorage, permanent: true);
  Get.put(AuthController(tokenStorage: tokenStorage), permanent: true);
  Get.put(
    DriverTrackingSocketService(tokenStorage: tokenStorage),
    permanent: true,
  );
  Get.put(NotificationService(), permanent: true);
  Get.put(ThemeController(), permanent: true);
  Get.put(AppLocationController(), permanent: true);
  Get.put(LocationOnOpenController(), permanent: true);

  final localNotifications = LocalNotificationsService.instance();
  await localNotifications.init();
  Get.put(localNotifications, permanent: true);

  Get.find<AuthController>().loadStoredAuth();
  Get.put(AppUpdateController(), permanent: true);
  Get.lazyPut<LoginController>(() => LoginController(), fenix: true);
  Get.lazyPut<RegisterController>(() => RegisterController(), fenix: true);
  Get.lazyPut<MainShellController>(() => MainShellController(), fenix: true);
  Get.lazyPut<CartController>(() => CartController(), fenix: true);
  Get.lazyPut<OrdersController>(() => OrdersController(), fenix: true);
  Get.lazyPut<HomeShopsController>(() => HomeShopsController(), fenix: true);
  Get.lazyPut<HomeProductsController>(() => HomeProductsController(), fenix: true);
  Get.lazyPut<CategoriesController>(() => CategoriesController(), fenix: true);
  Get.lazyPut<ContactInfoController>(() => ContactInfoController(), fenix: true);
  await _requestIosNotificationPermission();
   await _logFcmToken();
  _setupNotificationTapHandling(localNotifications);
  runApp(const QarypApp());
}

class QarypApp extends StatelessWidget {
  const QarypApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, __) => Obx(() {
        final theme = Get.find<ThemeController>();
        return GetMaterialApp(
          title: 'qaryp',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: theme.themeMode,
          builder: (context, child) => Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          ),
          initialRoute: '/',
          getPages: [
            GetPage(name: '/', page: () => const AuthWrapper()),
            GetPage(name: '/login', page: () => const LoginScreen()),
            GetPage(name: '/register', page: () => const RegisterScreen()),
            GetPage(
              name: '/location-gate',
              page: () => const LocationGateScreen(),
              binding: BindingsBuilder(() { Get.put(LocationGateController()); }),
            ),
            GetPage(
              name: '/location-required',
              page: () => const LocationRequiredScreen(),
              binding: BindingsBuilder(() { Get.put(LocationRequiredController()); }),
            ),
            GetPage(name: '/home', page: () => const MainShell()),
            GetPage(
              name: '/product',
              page: () => const ProductDetailScreen(),
              binding: BindingsBuilder(() { Get.put(ProductDetailController()); }),
            ),
            GetPage(
              name: '/shop-products',
              page: () => const ShopProductsScreen(),
              binding: BindingsBuilder(() { Get.put(ShopProductsController()); }),
            ),
            GetPage(
              name: '/search',
              page: () => const SearchResultsScreen(),
              binding: BindingsBuilder(() { Get.put(SearchProductsController()); }),
            ),
            GetPage(name: '/cart', page: () => const CartScreen()),
            GetPage(
              name: '/order-detail',
              page: () => const OrderDetailScreen(),
              binding: BindingsBuilder(() { Get.put(OrderDetailController()); }),
            ),
            GetPage(name: '/static-content', page: () => const StaticContentScreen()),
            GetPage(
              name: '/edit-profile',
              page: () => const EditProfileScreen(),
              binding: BindingsBuilder(() { Get.put(EditProfileController()); }),
            ),
            GetPage(
              name: '/full-screen-map',
              page: () => const FullScreenMapScreen(),
              binding: BindingsBuilder(() { Get.put(FullScreenMapController()); }),
            ),
            GetPage(
              name: '/voice-order',
              page: () => const VoiceOrderScreen(),
              binding: BindingsBuilder(() { Get.put(VoiceOrderController()); }),
            ),
            GetPage(
              name: '/all-shops',
              page: () => const AllShopsScreen(),
              binding: BindingsBuilder(() { Get.put(AllShopsController()); }),
            ),
          ],
        );
      }),
    );
  }
}

/// يحدد الصفحة الأولى حسب حالة المصادقة.
/// للضيف: عرض LocationGateScreen (طلب الموقع) ثم MainShell.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return Obx(() {
      if (auth.isLoading.value) {
        return const Scaffold(body: FullPageLoading());
      }
      if (auth.isAuthenticated) {
        return const MainShell();
      }
      if (!Get.isRegistered<LocationGateController>()) {
        Get.put(LocationGateController(), permanent: false);
      }
      return const LocationGateScreen();
    });
  }
}
