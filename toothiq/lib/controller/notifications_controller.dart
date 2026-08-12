import 'package:get/get.dart';

import '../core/errors/api_error_handler.dart';
import '../core/navigation/notification_navigation.dart';
import '../model/notification_model.dart';
import '../service_layer/services/notification_inbox_service.dart';

class NotificationsController extends GetxController {
  final NotificationInboxService _inbox = Get.find<NotificationInboxService>();

  final notifications = <AppNotificationModel>[].obs;
  final isLoading = false.obs;
  final loadError = RxnString();

  bool get hasUnread => notifications.any((n) => !n.isRead);

  @override
  void onInit() {
    super.onInit();
    loadFromInbox();
  }

  Future<void> loadFromInbox() async {
    isLoading.value = true;
    loadError.value = null;
    try {
      notifications.assignAll(await _inbox.syncFromServer());
      await _inbox.syncUnreadBadge();
    } catch (error) {
      loadError.value = ApiErrorHandler.loadMessage(
        error,
        fallback: 'تعذر تحميل الإشعارات',
      );
      notifications.assignAll(await _inbox.loadAll());
    } finally {
      isLoading.value = false;
    }
  }

  /// تحديث القائمة من المحلي فقط (بعد وصول FCM) بدون مسح ما وصل من Push.
  Future<void> reloadFromLocal() async {
    notifications.assignAll(await _inbox.loadAll());
    await _inbox.syncUnreadBadge();
  }

  List<AppNotificationModel> byGroup(NotificationDayGroup group) {
    return notifications.where((n) => n.group == group).toList();
  }

  /// تعليم الكل مقروءاً عند مغادرة الصفحة (مثل Art Inspiration).
  Future<void> markAllAsRead() async {
    await _inbox.markAllAsRead();
    notifications.assignAll(
      notifications.map((n) => n.copyWith(isRead: true)).toList(),
    );
  }

  /// الضغط يفتح الطلب/المنتج/المتجر إن وُجد — لا يعلّم الإشعار مقروءاً (القراءة عند المغادرة).
  void onNotificationTap(AppNotificationModel item) {
    if (!item.canOpenTarget) return;
    navigateFromNotificationPayload(
      item.type,
      orderId: item.orderId,
      productId: item.productId,
      shopId: item.shopId,
      storeId: item.storeId,
    );
  }

  @override
  Future<void> refresh() async {
    await loadFromInbox();
  }
}
