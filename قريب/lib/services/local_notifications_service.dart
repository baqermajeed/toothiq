import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// يعرض الإشعارات المحلية عند استقبال رسائل FCM أثناء فتح التطبيق.
class LocalNotificationsService {
  LocalNotificationsService._();

  static final LocalNotificationsService _instance = LocalNotificationsService._();

  factory LocalNotificationsService.instance() => _instance;

  late FlutterLocalNotificationsPlugin _plugin;

  static const _channelId = 'qaryp_notifications';
  static const _channelName = 'إشعارات التطبيق';

  int _notificationId = 0;

  /// دالة تُستدعى عند النقر على الإشعار (type, orderId)
  void Function(String? type, String? orderId)? onNotificationTap;

  /// تهيئة الإشعارات المحلية.
  Future<void> init() async {
    _plugin = FlutterLocalNotificationsPlugin();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: android,
        iOS: darwin,
        macOS: darwin,
      ),
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: 'إشعارات الطلبات والتحديثات',
          importance: Importance.max,
        ),
      );
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    try {
      final data = jsonDecode(payload) as Map<String, dynamic>?;
      final type = data?['type'] as String?;
      final orderId = data?['orderId'] as String?;
      onNotificationTap?.call(type, orderId);
    } catch (_) {}
  }

  /// عرض إشعار محلي.
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'إشعارات الطلبات والتحديثات',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails(
      presentSound: true,
      sound: 'default',
    );

    await _plugin.show(
      _notificationId++,
      title,
      body,
      const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
        macOS: iosDetails,
      ),
      payload: payload,
    );
  }
}
