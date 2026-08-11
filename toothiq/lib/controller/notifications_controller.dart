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

  @override
  void onInit() {
    super.onInit();
    loadFromInbox();
  }

  Future<void> loadFromInbox() async {
    isLoading.value = true;
    loadError.value = null;
    try {
      notifications.assignAll(await _inbox.loadAll());
    } catch (error) {
      loadError.value = ApiErrorHandler.loadMessage(
        error,
        fallback: 'تعذر تحميل الإشعارات',
      );
    } finally {
      isLoading.value = false;
    }
  }

  List<AppNotificationModel> byGroup(NotificationDayGroup group) {
    return notifications.where((n) => n.group == group).toList();
  }

  Future<void> onNotificationTap(AppNotificationModel item) async {
    await _inbox.markAsRead(item.id);
    if (item.isOrderNotification) {
      navigateFromNotificationPayload(item.type, item.orderId);
    }
  }

  @override
  Future<void> refresh() async {
    await loadFromInbox();
  }
}
