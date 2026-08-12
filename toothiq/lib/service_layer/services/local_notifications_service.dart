import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// يعرض الإشعارات المحلية عند استقبال FCM أثناء فتح التطبيق (مثل قريب).
class LocalNotificationsService {
  LocalNotificationsService._();

  static final LocalNotificationsService _instance = LocalNotificationsService._();

  factory LocalNotificationsService.instance() => _instance;

  late FlutterLocalNotificationsPlugin _plugin;

  static const _channelId = 'toothiq_notifications';
  static const _channelName = 'ToothIQ';

  int _notificationId = 0;

  void Function(Map<String, String?> data)? onNotificationTap;

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
      final decoded = jsonDecode(payload) as Map<String, dynamic>?;
      if (decoded == null) return;
      final data = <String, String?>{};
      for (final entry in decoded.entries) {
        data[entry.key] = entry.value?.toString();
      }
      onNotificationTap?.call(data);
    } catch (_) {}
  }

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
