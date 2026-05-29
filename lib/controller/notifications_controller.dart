import 'package:get/get.dart';

import '../model/notification_model.dart';

class NotificationsController extends GetxController {
  final notifications = <AppNotificationModel>[
    const AppNotificationModel(
      id: '1',
      title: 'تمت مراجعة طلبك',
      description:
          'تمت مراجعة طلبك بنجاح ، يمكنك متابعة حالة الطلب من صفحة طلباتك',
      timeLabel: 'الآن',
      group: NotificationDayGroup.today,
    ),
    const AppNotificationModel(
      id: '2',
      title: 'وصل التحديث الجديد !',
      description:
          'قم بتحديث التطبيق للاستفادة من الميزات الجديدة وتحسينات الأداء',
      timeLabel: 'منذ 10 دقائق',
      group: NotificationDayGroup.today,
      iconType: NotificationIconType.update,
    ),
    const AppNotificationModel(
      id: '3',
      title: 'تم شحن طلبك',
      description: 'طلبك في الطريق إليك ، تابع التوصيل من صفحة طلباتك',
      timeLabel: 'أمس',
      group: NotificationDayGroup.yesterday,
    ),
    const AppNotificationModel(
      id: '4',
      title: 'تم تأكيد الدفع',
      description: 'تم استلام دفعتك بنجاح ، شكراً لتسوقك معنا',
      timeLabel: 'أمس',
      group: NotificationDayGroup.yesterday,
    ),
    const AppNotificationModel(
      id: '5',
      title: 'تحديث في حالة الطلب',
      description: 'تغيّرت حالة طلبك ، اطلع على التفاصيل الآن',
      timeLabel: 'أمس',
      group: NotificationDayGroup.yesterday,
    ),
    const AppNotificationModel(
      id: '6',
      title: 'تم إلغاء الطلب',
      description: 'تم إلغاء طلبك حسب طلبك ، يمكنك إعادة الطلب في أي وقت',
      timeLabel: 'أمس',
      group: NotificationDayGroup.yesterday,
    ),
    const AppNotificationModel(
      id: '7',
      title: 'عرض خاص لك',
      description: 'استفد من خصم حصري على منتجات مختارة لفترة محدودة',
      timeLabel: 'أمس',
      group: NotificationDayGroup.yesterday,
    ),
  ].obs;

  List<AppNotificationModel> byGroup(NotificationDayGroup group) {
    return notifications.where((n) => n.group == group).toList();
  }

  void onNotificationTap(AppNotificationModel item) {
    // TODO: التنقل حسب نوع الإشعار
  }
}
