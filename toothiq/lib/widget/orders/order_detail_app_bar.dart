import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../utils/app_colors.dart';
import '../my_text.dart';

class OrderDetailAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const OrderDetailAppBar({super.key, this.title = 'تفاصيل الطلب'});

  @override
  Size get preferredSize => Size.fromHeight(56.h);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      title: MyText(
        title,
        fontSize: 18.sp,
        fontWeight: FontWeight.w800,
        color: AppColors.productTitle,
      ),
      actions: [
        Padding(
          padding: EdgeInsets.all(8.w),
          child: Material(
            color: AppColors.productStore,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: () => Get.back(),
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 40.w,
                height: 40.w,
                child: Icon(
                  Icons.chevron_right,
                  color: Colors.white,
                  size: 26.sp,
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 8.w),
      ],
    );
  }
}
