import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../controller/notifications_controller.dart';
import '../../firebase_options.dart';
import '../../model/notification_model.dart';
import '../../utils/storage_keys.dart';
import 'preferences_storage.dart';

/// صندوق الإشعارات المحلي — يُملأ من FCM ويُعرض في صفحة الإشعارات.
class NotificationInboxService extends GetxService {
  Future<List<AppNotificationModel>> loadAll() async {
    try {
      final raw = PreferencesStorage.instance.getJsonList(
        StorageKeys.notificationInbox,
      );
      if (raw == null || raw.isEmpty) return [];

      final items = <AppNotificationModel>[];
      for (final entry in raw) {
        try {
          items.add(AppNotificationModel.fromJson(entry));
        } catch (error) {
          if (kDebugMode) {
            debugPrint('[NotificationInbox] Skip invalid entry: $error');
          }
        }
      }
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[NotificationInbox] loadAll failed: $error');
      }
      return [];
    }
  }

  Future<void> addFromRemoteMessage(RemoteMessage message) async {
    final item = AppNotificationModel.fromRemoteMessage(message);
    if (item.title.trim().isEmpty && item.description.trim().isEmpty) return;
    await _addItem(item);
  }

  Future<void> addFromPayload({
    required String title,
    required String description,
    String? type,
    String? orderId,
  }) async {
    final item = AppNotificationModel(
      id: '${type ?? 'local'}_${orderId ?? ''}_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      createdAt: DateTime.now(),
      type: type,
      orderId: orderId,
    );
    await _addItem(item);
  }

  Future<void> _addItem(AppNotificationModel item) async {
    const maxItems = 100;
    final current = await loadAll();
    if (current.any((n) => n.id == item.id)) return;

    final updated = [item, ...current];
    if (updated.length > maxItems) {
      updated.removeRange(maxItems, updated.length);
    }

    await PreferencesStorage.instance.setJsonList(
      StorageKeys.notificationInbox,
      updated.map((n) => n.toJson()).toList(growable: false),
    );

    _refreshNotificationsController();
  }

  Future<void> markAsRead(String id) async {
    final current = await loadAll();
    final index = current.indexWhere((n) => n.id == id);
    if (index == -1) return;

    current[index] = current[index].copyWith(isRead: true);
    await PreferencesStorage.instance.setJsonList(
      StorageKeys.notificationInbox,
      current.map((n) => n.toJson()).toList(growable: false),
    );
    _refreshNotificationsController();
  }

  void _refreshNotificationsController() {
    if (!Get.isRegistered<NotificationsController>()) return;
    Get.find<NotificationsController>().loadFromInbox();
  }
}

/// معالج رسائل FCM في الخلفية — يحفظ الإشعار في الصندوق المحلي.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    debugPrint('[FCM] Background message: ${message.messageId}');
  }
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await PreferencesStorage.init();
    await NotificationInboxService().addFromRemoteMessage(message);
  } catch (error) {
    if (kDebugMode) {
      debugPrint('[FCM] Background save failed: $error');
    }
  }
}
