import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controller/home_controller.dart';
import '../utils/app_colors.dart';
import '../view/cart/cart_page.dart';
import '../view/notifications/notifications_page.dart';
import 'my_text.dart';

class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const MainAppBar({super.key, required this.title});

  @override
  Size get preferredSize => Size.fromHeight(56.h);

  @override
  Widget build(BuildContext context) {
    final hasNotification = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>().hasNotification
        : true.obs;

    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: true,
      title: MyText(
        title,
        fontSize: 20.sp,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
      leading: IconButton(
        onPressed: () => CartPage.open(),
        icon: Icon(
          Icons.shopping_cart_outlined,
          color: AppColors.primary,
          size: 28.sp,
        ),
      ),
      actions: [
        Obx(
          () => Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: () {
                  if (Get.isRegistered<HomeController>()) {
                    Get.find<HomeController>().hasNotification.value = false;
                  }
                  NotificationsPage.open();
                },
                icon: Icon(
                  Icons.notifications_none_rounded,
                  color: AppColors.primary,
                  size: 28.sp,
                ),
              ),
              if (hasNotification.value)
                Positioned(
                  top: 10.h,
                  right: 10.w,
                  child: Container(
                    width: 9.w,
                    height: 9.w,
                    decoration: const BoxDecoration(
                      color: AppColors.notificationBadge,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(width: 4.w),
      ],
    );
  }
}
