import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Must be top-level for background handler.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    debugPrint('[FCM] Background message: ${message.messageId}');
  }
}

/// Service for FCM: token, topics, and message handling.
class NotificationService {
  NotificationService() {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  /// Initialize and request permissions.
  Future<void> initialize() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// Get current FCM token.
  Future<String?> getToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      if (kDebugMode) debugPrint('[FCM] getToken error: $e');
      return null;
    }
  }

  /// اشتراك العميل في مواضيع الإشعارات (عميل فقط — لا اشتراك في drivers).
  Future<void> subscribeToTopics() async {
    try {
      await FirebaseMessaging.instance.subscribeToTopic('all_users');
    } catch (e) {
      if (kDebugMode) debugPrint('[FCM] subscribeToTopics error: $e');
    }
  }

  /// إلغاء الاشتراك من كل المواضيع عند تسجيل الخروج.
  Future<void> unsubscribeFromTopics() async {
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic('all_users');
    } catch (e) {
      if (kDebugMode) debugPrint('[FCM] unsubscribeFromTopics error: $e');
    }
  }

  /// Setup token refresh listener.
  void onTokenRefresh(void Function(String token) callback) {
    FirebaseMessaging.instance.onTokenRefresh.listen(callback);
  }

  /// Foreground message stream.
  Stream<RemoteMessage> get onMessage => FirebaseMessaging.onMessage;

  /// User tapped notification (app was in background).
  Stream<RemoteMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp;

  /// Get initial message when app opened from terminated state.
  Future<RemoteMessage?> getInitialMessage() =>
      FirebaseMessaging.instance.getInitialMessage();
}
