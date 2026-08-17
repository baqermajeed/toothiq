import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    debugPrint('[FCM] Background message: ${message.messageId}');
  }
}

class NotificationService {
  bool _refreshListening = false;

  Future<void> initialize() async {
    await FirebaseMessaging.instance.setAutoInitEnabled(true);
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
  }

  Future<String?> getToken() async {
    for (var attempt = 0; attempt < 4; attempt++) {
      try {
        if (attempt > 0) {
          await Future<void>.delayed(Duration(seconds: attempt * 2));
        }
        final token = await FirebaseMessaging.instance
            .getToken()
            .timeout(const Duration(seconds: 12));
        if (token != null && token.isNotEmpty) {
          if (kDebugMode) {
            debugPrint('[FCM] token ready (${token.length} chars)');
          }
          return token;
        }
      } catch (error) {
        if (kDebugMode) {
          debugPrint('[FCM] getToken attempt $attempt error: $error');
        }
      }
    }
    return null;
  }

  Future<void> subscribeForRole({
    required bool isShop,
    String? shopId,
  }) async {
    try {
      final messaging = FirebaseMessaging.instance;
      if (isShop) {
        await messaging.subscribeToTopic('all_shops');
        await messaging.unsubscribeFromTopic('all_drivers');
        final id = shopId?.trim();
        if (id != null && id.isNotEmpty) {
          await messaging.subscribeToTopic('shop_$id');
        }
      } else {
        await messaging.subscribeToTopic('all_drivers');
        await messaging.unsubscribeFromTopic('all_shops');
      }
    } catch (error) {
      if (kDebugMode) debugPrint('[FCM] subscribeForRole error: $error');
    }
  }

  Future<void> unsubscribeAll({String? shopId}) async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.unsubscribeFromTopic('all_shops');
      await messaging.unsubscribeFromTopic('all_drivers');
      final id = shopId?.trim();
      if (id != null && id.isNotEmpty) {
        await messaging.unsubscribeFromTopic('shop_$id');
      }
    } catch (error) {
      if (kDebugMode) debugPrint('[FCM] unsubscribeAll error: $error');
    }
  }

  void onTokenRefresh(void Function(String token) callback) {
    if (_refreshListening) return;
    _refreshListening = true;
    FirebaseMessaging.instance.onTokenRefresh.listen(callback);
  }
}
