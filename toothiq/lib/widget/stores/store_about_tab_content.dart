import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controller/store_detail_controller.dart';
import '../../utils/app_colors.dart';
import '../my_text.dart';

class StoreAboutTabContent extends StatelessWidget {
  final StoreDetailController controller;
  final bool embedInParentScroll;

  const StoreAboutTabContent({
    super.key,
    required this.controller,
    this.embedInParentScroll = false,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final description = controller.aboutDescription.value.trim();

      final content = Padding(
        padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 24.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MyText(
              'وصف المتجر',
              fontSize: 17.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.productTitle,
              textAlign: TextAlign.right,
            ),
            SizedBox(height: 14.h),
            MyText(
              description.isEmpty ? 'لا يوجد وصف لهذا المتجر حالياً' : description,
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              textAlign: TextAlign.right,
              height: 1.65,
            ),
          ],
        ),
      );

      if (embedInParentScroll) return content;

      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: content,
      );
    });
  }
}
