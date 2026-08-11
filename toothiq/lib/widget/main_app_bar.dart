import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controller/home_controller.dart';
import '../utils/app_colors.dart';
import '../view/basket/basket_page.dart';
import '../view/notifications/notifications_page.dart';
import 'cart/cart_icon.dart';
import 'my_text.dart';

class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const MainAppBar({super.key, required this.title});

  @override
  Size get preferredSize => Size.fromHeight(56.h);

  @override
  Widget build(BuildContext context) {
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
        onPressed: () => BasketPage.open(),
        icon: CartIcon(size: 28.sp),
      ),
      actions: [
        IconButton(
          onPressed: () {
            if (Get.isRegistered<HomeController>()) {
              Get.find<HomeController>().hasNotification.value = false;
            }
            NotificationsPage.open();
          },
          icon: Image.asset(
            'assets/images/cart/not12.png',
            width: 28.w,
            height: 28.w,
            fit: BoxFit.contain,
          ),
        ),
        SizedBox(width: 4.w),
      ],
    );
  }
}
