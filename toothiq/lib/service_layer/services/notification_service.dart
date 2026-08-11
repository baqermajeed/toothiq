import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'notification_inbox_service.dart' show firebaseMessagingBackgroundHandler;

export 'notification_inbox_service.dart' show firebaseMessagingBackgroundHandler;

/// خدمة FCM — مطابقة لتطبيق قريب.
class NotificationService {
  NotificationService() {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  Future<void> initialize() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<String?> getToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (error) {
      if (kDebugMode) debugPrint('[FCM] getToken error: $error');
      return null;
    }
  }

  Future<void> subscribeToTopics() async {
    try {
      await FirebaseMessaging.instance.subscribeToTopic('all_users');
    } catch (error) {
      if (kDebugMode) debugPrint('[FCM] subscribeToTopics error: $error');
    }
  }

  Future<void> unsubscribeFromTopics() async {
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic('all_users');
    } catch (error) {
      if (kDebugMode) debugPrint('[FCM] unsubscribeFromTopics error: $error');
    }
  }

  void onTokenRefresh(void Function(String token) callback) {
    FirebaseMessaging.instance.onTokenRefresh.listen(callback);
  }

  Stream<RemoteMessage> get onMessage => FirebaseMessaging.onMessage;

  Stream<RemoteMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp;

  Future<RemoteMessage?> getInitialMessage() =>
      FirebaseMessaging.instance.getInitialMessage();
}
