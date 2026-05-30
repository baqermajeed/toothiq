import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../utils/app_colors.dart';
import '../../view/main_page.dart';
import '../../widget/basket/checkout_step_indicator.dart';
import '../../widget/my_text.dart';
import '../../widget/primary_button.dart';

/// مرحلة ٣ — تم إرسال الطلب بنجاح
class OrderSuccessPage extends StatelessWidget {
  const OrderSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              const CheckoutStepIndicator(currentIndex: 2),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 28.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 96.w,
                        height: 96.w,
                        decoration: BoxDecoration(
                          color: AppColors.orderStatusDeliveredBg,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          size: 52.sp,
                          color: AppColors.orderDetailPriceGreen,
                        ),
                      ),
                      SizedBox(height: 24.h),
                      MyText(
                        'تم إرسال طلبك بنجاح',
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.productTitle,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 12.h),
                      MyText(
                        'سيتم التواصل معك قريباً لتأكيد الطلب وتحديد موعد التوصيل',
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                        textAlign: TextAlign.center,
                        height: 1.6,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 24.h),
                child: PrimaryButton(
                  label: 'العودة للرئيسية',
                  onPressed: () => Get.offAll(() => const MainPage()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
