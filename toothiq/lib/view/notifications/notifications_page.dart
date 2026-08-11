import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../bindings/notifications_binding.dart';
import '../../controller/notifications_controller.dart';
import '../../model/notification_model.dart';
import '../../utils/app_colors.dart';
import '../../widget/common/async_state_widgets.dart';
import '../../widget/my_text.dart';
import '../../widget/notifications/notification_card_widget.dart';
import '../../widget/section/section_app_bar.dart';

class NotificationsPage extends GetView<NotificationsController> {
  const NotificationsPage({super.key});

  static void open() {
    Get.to(
      () => const NotificationsPage(),
      binding: NotificationsBinding(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.settingsPageBackground,
        appBar: const SectionAppBar(title: 'الأشعارات'),
        body: Obx(() {
          if (controller.isLoading.value && controller.notifications.isEmpty) {
            return const AppLoadingState();
          }

          if (controller.loadError.value != null &&
              controller.notifications.isEmpty) {
            return AppErrorState(
              message: controller.loadError.value!,
              onRetry: controller.refresh,
            );
          }

          if (controller.notifications.isEmpty) {
            return const AppEmptyState(
              title: 'لا توجد إشعارات',
              subtitle: 'ستظهر إشعاراتك هنا عند وصولها',
              icon: Icons.notifications_none_rounded,
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: controller.refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
              children: [
                _NotificationSection(
                  title: 'اليوم',
                  items: controller.byGroup(NotificationDayGroup.today),
                  onTap: controller.onNotificationTap,
                ),
                SizedBox(height: 8.h),
                _NotificationSection(
                  title: 'أمس',
                  items: controller.byGroup(NotificationDayGroup.yesterday),
                  onTap: controller.onNotificationTap,
                ),
                SizedBox(height: 8.h),
                _NotificationSection(
                  title: 'أقدم',
                  items: controller.byGroup(NotificationDayGroup.older),
                  onTap: controller.onNotificationTap,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _NotificationSection extends StatelessWidget {
  final String title;
  final List<AppNotificationModel> items;
  final void Function(AppNotificationModel item) onTap;

  const _NotificationSection({
    required this.title,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MyText(
          title,
          fontSize: 16.sp,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
          textAlign: TextAlign.right,
        ),
        SizedBox(height: 10.h),
        ...items.map(
          (item) => Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: NotificationCardWidget(
              notification: item,
              onTap: () => onTap(item),
            ),
          ),
        ),
      ],
    );
  }
}
