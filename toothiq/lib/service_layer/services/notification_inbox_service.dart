import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../controller/notifications_controller.dart';
import '../../core/api/api_client.dart';
import '../../firebase_options.dart';
import '../../model/notification_model.dart';
import '../../utils/storage_keys.dart';
import 'preferences_storage.dart';

/// صندوق الإشعارات — يُزامَن من السيرفر ويُحدَّث من FCM.
class NotificationInboxService extends GetxService {
  /// أحمر في الهيدر عند وجود أي إشعار غير مقروء.
  final hasUnread = false.obs;

  ApiClient? get _api {
    if (!Get.isRegistered<ApiClient>()) return null;
    return Get.find<ApiClient>();
  }

  @override
  void onInit() {
    super.onInit();
    syncUnreadBadge();
  }

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

  /// يجلب الإشعارات من السيرفر ويحدّث الصندوق المحلي.
  Future<List<AppNotificationModel>> syncFromServer() async {
    final api = _api;
    if (api == null) return loadAll();

    try {
      final result = await api.getNotifications();
      await PreferencesStorage.instance.setJsonList(
        StorageKeys.notificationInbox,
        result.items.map((n) => n.toJson()).toList(growable: false),
      );
      hasUnread.value = result.unreadCount > 0 ||
          result.items.any((n) => !n.isRead);
      _refreshNotificationsController();
      return result.items;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[NotificationInbox] syncFromServer failed: $error');
      }
      return loadAll();
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

    await _afterInboxChanged();
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
    await _api?.markNotificationRead(id);
    await _afterInboxChanged();
  }

  /// يعلّم كل الإشعارات مقروءة — يُستدعى عند مغادرة صفحة الإشعارات.
  Future<void> markAllAsRead() async {
    final current = await loadAll();
    if (current.isEmpty || current.every((n) => n.isRead)) {
      await syncUnreadBadge();
      return;
    }

    final updated = current
        .map((n) => n.isRead ? n : n.copyWith(isRead: true))
        .toList(growable: false);

    await PreferencesStorage.instance.setJsonList(
      StorageKeys.notificationInbox,
      updated.map((n) => n.toJson()).toList(growable: false),
    );
    await _api?.markAllNotificationsRead();
    await syncUnreadBadge();
  }

  Future<void> syncUnreadBadge() async {
    final api = _api;
    if (api != null) {
      try {
        final count = await api.getNotificationsUnreadCount();
        hasUnread.value = count > 0;
        return;
      } catch (_) {}
    }
    hasUnread.value = (await loadAll()).any((n) => !n.isRead);
  }

  Future<void> _afterInboxChanged() async {
    _refreshNotificationsController();
    await syncUnreadBadge();
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
