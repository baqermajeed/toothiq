import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../controller/cart_controller.dart';
import '../../utils/app_colors.dart';
import '../my_text.dart';

/// شريط إكمال الشراء — انحناء علوي للأعلى
class CartBottomBar extends StatelessWidget {
  final CartController controller;

  const CartBottomBar({super.key, required this.controller});

  static const double _topRadius = 32;
  static const double _buttonHeight = 54;

  @override
  Widget build(BuildContext context) {
    final topRadius = Radius.circular(_topRadius.r);

    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: topRadius,
        topRight: topRadius,
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.bottomNavBackground,
          borderRadius: BorderRadius.only(
            topLeft: topRadius,
            topRight: topRadius,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 18,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 18.h),
            child: SizedBox(
              width: double.infinity,
              height: _buttonHeight.h,
              child: Material(
                color: Colors.white,
                elevation: 0,
                borderRadius: BorderRadius.circular(_buttonHeight.h / 2),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: controller.completePurchase,
                  borderRadius: BorderRadius.circular(_buttonHeight.h / 2),
                  child: Center(
                    child: MyText(
                      'أكمال الشراء',
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.productTitle,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
