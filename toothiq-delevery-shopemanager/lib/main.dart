import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'bindings/app_binding.dart';
import 'core/navigation/partner_notification_router.dart';
import 'controller/driver_orders_controller.dart';
import 'controller/shop_orders_controller.dart';
import 'firebase_options.dart';
import 'service_layer/services/driver_tracking_socket_service.dart';
import 'service_layer/services/local_notifications_service.dart';
import 'service_layer/services/notification_service.dart';
import 'service_layer/services/preferences_storage.dart';
import 'utils/app_colors.dart';
import 'view/splash/splash_page.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await PreferencesStorage.init();
    await _initNotifications();

    runApp(const ToothiqPartnerApp());
  }, (Object error, StackTrace stack) {
    if (kDebugMode) {
      debugPrint('[ToothIQ Partner] UNCAUGHT ERROR: $error');
      debugPrint('[ToothIQ Partner] STACK: $stack');
    }
    FlutterError.reportError(
      FlutterErrorDetails(exception: error, stack: stack),
    );
  });
}

Future<void> _initNotifications() async {
  final localNotifications = LocalNotificationsService.instance();
  await localNotifications.init();

  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    provisional: false,
  );
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  localNotifications.onNotificationTap = PartnerNotificationRouter.handle;

  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    PartnerNotificationRouter.handle(_remoteData(initialMessage));
  }

  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    PartnerNotificationRouter.handle(_remoteData(message));
  });

  FirebaseMessaging.onMessage.listen((message) async {
    if (Get.isRegistered<ShopOrdersController>()) {
      Get.find<ShopOrdersController>().loadOrders(silent: true);
    }
    if (Get.isRegistered<DriverOrdersController>()) {
      Get.find<DriverOrdersController>().loadOrders(silent: true);
    }

    final data = _remoteData(message);
    final type = data['type'];
    final socketAlreadyNotified = (type == 'shop_new_order' ||
            type == 'driver_new_order') &&
        Get.isRegistered<DriverTrackingSocketService>() &&
        Get.find<DriverTrackingSocketService>().isConnected;
    if (socketAlreadyNotified) return;

    final title = message.notification?.title;
    final body = message.notification?.body;
    if (title == null && body == null) return;

    await localNotifications.showNotification(
      title: title ?? 'إشعار',
      body: body ?? '',
      payload: jsonEncode(data),
    );
  });
}

Map<String, String?> _remoteData(RemoteMessage message) {
  return message.data.map((key, value) => MapEntry(key, value?.toString()));
}

class ToothiqPartnerApp extends StatelessWidget {
  const ToothiqPartnerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(393, 852),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          title: 'ToothIQ Partner',
          debugShowCheckedModeBanner: false,
          locale: const Locale('ar'),
          fallbackLocale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            useMaterial3: true,
            fontFamily: 'Expo Arabic',
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              primary: AppColors.primary,
            ),
            scaffoldBackgroundColor: AppColors.background,
            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.background,
              foregroundColor: AppColors.textPrimary,
              elevation: 0,
              centerTitle: true,
            ),
          ),
          home: const SplashPage(),
          initialBinding: AppBinding(),
          defaultTransition: Transition.fadeIn,
          transitionDuration: const Duration(milliseconds: 220),
        );
      },
    );
  }
}
