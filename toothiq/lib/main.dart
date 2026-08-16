import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';

import 'bindings/app_binding.dart';
import 'core/navigation/app_route_observer.dart';
import 'core/navigation/notification_navigation.dart';
import 'firebase_options.dart';
import 'service_layer/services/local_notifications_service.dart';
import 'service_layer/services/notification_inbox_service.dart';
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
    await PreferencesStorage.init();
    Get.put(NotificationInboxService(), permanent: true);
    await _initNotifications();

    runApp(const DentalApp());
  }, (Object error, StackTrace stack) {
    if (kDebugMode) {
      debugPrint('[Toothiq] UNCAUGHT ERROR: $error');
      debugPrint('[Toothiq] STACK: $stack');
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

  try {
    final token = await FirebaseMessaging.instance.getToken();
    debugPrint('FCM Token: $token');
  } catch (error, stackTrace) {
    debugPrint('FCM Token ERROR: $error');
    debugPrint('$stackTrace');
  }

  localNotifications.onNotificationTap = (data) {
    navigateFromNotificationPayload(
      data['type'],
      orderId: data['orderId'],
      productId: data['productId'],
      shopId: data['shopId'],
      storeId: data['storeId'],
      data: data,
    );
  };

  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    await Get.find<NotificationInboxService>().addFromRemoteMessage(
      initialMessage,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleRemoteMessageNavigation(initialMessage);
    });
  }

  FirebaseMessaging.onMessageOpenedApp.listen(_handleRemoteMessageNavigation);
  FirebaseMessaging.onMessage.listen((message) async {
    await Get.find<NotificationInboxService>().addFromRemoteMessage(message);

    final title = message.notification?.title;
    final body = message.notification?.body;
    if (title == null && body == null) return;

    final data = message.data;
    await localNotifications.showNotification(
      title: title ?? 'إشعار',
      body: body ?? '',
      payload: jsonEncode({
        'type': data['type'],
        'orderId': data['orderId'],
        'productId': data['productId'],
        'shopId': data['shopId'],
        'storeId': data['storeId'],
      }),
    );
  });

  FirebaseMessaging.instance.onTokenRefresh.listen((token) {
    debugPrint('FCM Token (refreshed): $token');
  });
}

void _handleRemoteMessageNavigation(RemoteMessage message) async {
  await Get.find<NotificationInboxService>().addFromRemoteMessage(message);
  final data = message.data.map(
    (key, value) => MapEntry(key, value?.toString()),
  );
  navigateFromNotificationPayload(
    data['type'],
    orderId: data['orderId'],
    productId: data['productId'],
    shopId: data['shopId'],
    storeId: data['storeId'],
    data: data,
  );
}

class DentalApp extends StatelessWidget {
  const DentalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(393, 852),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          title: 'ToothIQ',
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
              surface: AppColors.background,
            ),
            scaffoldBackgroundColor: AppColors.background,
            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.background,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              shadowColor: Colors.transparent,
            ),
          ),
          home: const SplashPage(),
          initialBinding: AppBinding(),
          navigatorObservers: [appRouteObserver],
          defaultTransition: Transition.fadeIn,
          transitionDuration: const Duration(milliseconds: 220),
        );
      },
    );
  }
}
