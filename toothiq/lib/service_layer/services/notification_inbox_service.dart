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

/// صندوق الإشعارات — يُزامَن من السيرفر ويُحدَّث من FCM بدون مسح المحلي.
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

  Future<void> _persist(List<AppNotificationModel> items) async {
    const maxItems = 100;
    final trimmed = List<AppNotificationModel>.from(items)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (trimmed.length > maxItems) {
      trimmed.removeRange(maxItems, trimmed.length);
    }
    await PreferencesStorage.instance.setJsonList(
      StorageKeys.notificationInbox,
      trimmed.map((n) => n.toJson()).toList(growable: false),
    );
  }

  /// يدمج قوائم الإشعارات مع تفضيل نسخة السيرفر عند تطابق المعرّف.
  List<AppNotificationModel> _merge({
    required List<AppNotificationModel> server,
    required List<AppNotificationModel> local,
  }) {
    final byId = <String, AppNotificationModel>{};
    for (final item in local) {
      if (item.id.isEmpty) continue;
      byId[item.id] = item;
    }
    for (final item in server) {
      if (item.id.isEmpty) continue;
      byId[item.id] = item;
    }

    // إزالة تكرار منطقي لنفس الإشعار التسويقي (نوع + هدف + عنوان) خلال ساعة.
    final deduped = <AppNotificationModel>[];
    for (final item in byId.values) {
      final duplicate = deduped.any((existing) {
        if (existing.id == item.id) return true;
        if (existing.type != item.type) return false;
        if (existing.title != item.title) return false;
        if (existing.description != item.description) return false;
        final sameTarget =
            (existing.orderId ?? '') == (item.orderId ?? '') &&
            (existing.productId ?? '') == (item.productId ?? '') &&
            (existing.shopId ?? '') == (item.shopId ?? '') &&
            (existing.storeId ?? '') == (item.storeId ?? '');
        if (!sameTarget) return false;
        return existing.createdAt
                .difference(item.createdAt)
                .abs()
                .inMinutes <
            60;
      });
      if (!duplicate) deduped.add(item);
    }

    deduped.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return deduped;
  }

  /// يجلب الإشعارات من السيرفر ويدمجها مع المحلي (لا يمسح إشعارات FCM).
  Future<List<AppNotificationModel>> syncFromServer() async {
    final api = _api;
    final local = await loadAll();
    if (api == null) return local;

    try {
      final result = await api.getNotifications();
      final merged = _merge(server: result.items, local: local);
      await _persist(merged);
      hasUnread.value =
          merged.any((n) => !n.isRead) || result.unreadCount > 0;
      return merged;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[NotificationInbox] syncFromServer failed: $error');
      }
      return local;
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
    String? productId,
    String? shopId,
    String? storeId,
  }) async {
    final item = AppNotificationModel(
      id: '${type ?? 'local'}_${orderId ?? productId ?? storeId ?? ''}_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      createdAt: DateTime.now(),
      type: type,
      orderId: orderId,
      productId: productId,
      shopId: shopId,
      storeId: storeId,
    );
    await _addItem(item);
  }

  Future<void> _addItem(AppNotificationModel item) async {
    final current = await loadAll();
    if (current.any((n) => n.id == item.id)) {
      await syncUnreadBadge();
      return;
    }

    final updated = _merge(server: [item], local: current);
    await _persist(updated);
    await syncUnreadBadge();
    _refreshNotificationsControllerLocal();
  }

  Future<void> markAsRead(String id) async {
    final current = await loadAll();
    final index = current.indexWhere((n) => n.id == id);
    if (index == -1) return;

    current[index] = current[index].copyWith(isRead: true);
    await _persist(current);
    await _api?.markNotificationRead(id);
    await syncUnreadBadge();
    _refreshNotificationsControllerLocal();
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

    await _persist(updated);
    await _api?.markAllNotificationsRead();
    await syncUnreadBadge();
  }

  Future<void> syncUnreadBadge() async {
    final localUnread = (await loadAll()).any((n) => !n.isRead);
    final api = _api;
    if (api != null) {
      try {
        final count = await api.getNotificationsUnreadCount();
        hasUnread.value = count > 0 || localUnread;
        return;
      } catch (_) {}
    }
    hasUnread.value = localUnread;
  }

  void _refreshNotificationsControllerLocal() {
    if (!Get.isRegistered<NotificationsController>()) return;
    Get.find<NotificationsController>().reloadFromLocal();
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
