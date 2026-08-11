import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controller/order_detail_controller.dart';
import '../../utils/app_colors.dart';
import '../my_text.dart';

class OrderDetailBottomBar extends StatelessWidget {
  final OrderDetailController controller;

  const OrderDetailBottomBar({required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 20.h),
        decoration: BoxDecoration(
          color: AppColors.bottomNavBackground,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24.r),
            topRight: Radius.circular(24.r),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 50.h,
                  child: ElevatedButton(
                    onPressed: controller.isReordering.value
                        ? null
                        : controller.onReorder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                    child: controller.isReordering.value
                        ? SizedBox(
                            width: 20.w,
                            height: 20.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.productTitle,
                            ),
                          )
                        : MyText(
                            'أعادة الطلب',
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.productTitle,
                          ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                flex: 2,
                child: TextButton(
                  onPressed: controller.onViewStore,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                  ),
                  child: MyText(
                    'عرض المتجر',
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
