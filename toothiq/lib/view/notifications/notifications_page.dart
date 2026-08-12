import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../bindings/notifications_binding.dart';
import '../../controller/notifications_controller.dart';
import '../../model/notification_model.dart';
import '../../utils/app_colors.dart';
import '../../widget/app_back_button.dart';
import '../../widget/common/async_state_widgets.dart';
import '../../widget/notifications/notification_card_widget.dart';

class NotificationsPage extends GetView<NotificationsController> {
  const NotificationsPage({super.key});

  static void open() {
    Get.to(
      () => const NotificationsPage(),
      binding: NotificationsBinding(),
    );
  }

  Future<void> _markReadAndLeave() async {
    await controller.markAllAsRead();
    if (Get.key.currentState?.canPop() ?? false) {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) _markReadAndLeave();
        },
        child: Scaffold(
          backgroundColor: NotificationCardMetrics.pageBackground,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _NotificationsHeader(onBack: _markReadAndLeave),
                Expanded(
                  child: Obx(() {
                    if (controller.isLoading.value &&
                        controller.notifications.isEmpty) {
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
                      return RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: controller.refresh,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          children: [
                            SizedBox(height: 160.h),
                            Center(
                              child: Text(
                                'لا توجد إشعارات',
                                style: TextStyle(
                                  fontFamily: 'Expo Arabic',
                                  fontSize: 15.96.sp,
                                  fontWeight: FontWeight.w700,
                                  height: 1.5,
                                  color: const Color(0xFF022B2F)
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: controller.refresh,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: EdgeInsets.fromLTRB(
                          20.w,
                          0,
                          20.w,
                          24.h + bottomInset,
                        ),
                        children: [
                          for (final group in NotificationDayGroup.values) ...[
                            if (controller.byGroup(group).isNotEmpty) ...[
                              _GroupHeader(label: group.groupTitle),
                              SizedBox(height: 12.h),
                              for (final item
                                  in controller.byGroup(group)) ...[
                                NotificationCardWidget(
                                  notification: item,
                                  onTap: item.canOpenTarget
                                      ? () =>
                                          controller.onNotificationTap(item)
                                      : null,
                                ),
                                SizedBox(height: 12.h),
                              ],
                              SizedBox(height: 8.h),
                            ],
                          ],
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension on NotificationDayGroup {
  String get groupTitle => switch (this) {
        NotificationDayGroup.today => 'اليوم',
        NotificationDayGroup.yesterday => 'أمس',
        NotificationDayGroup.older => 'أقدم',
      };
}

class _NotificationsHeader extends StatelessWidget {
  const _NotificationsHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 16.h),
      child: Row(
        textDirection: TextDirection.ltr,
        children: [
          AppBackButton(onPressed: onBack),
          Expanded(
            child: Text(
              'الأشعارات',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Expo Arabic',
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.productTitle,
              ),
            ),
          ),
          SizedBox(width: 34.w + 12.w),
        ],
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Expo Arabic',
            fontSize: 15.96.sp,
            fontWeight: FontWeight.w700,
            height: 1.5,
            color: const Color(0xFF022B2F).withValues(alpha: 0.6),
          ),
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }
}
