import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../utils/app_colors.dart';
import '../cart/cart_icon.dart';
import '../my_text.dart';

enum CartConfirmType {
  clearCart,
  removeItem,
}

class CartConfirmDialog extends StatelessWidget {
  final CartConfirmType type;

  const CartConfirmDialog({super.key, required this.type});

  static Future<bool?> show(CartConfirmType type) {
    return Get.dialog<bool>(
      CartConfirmDialog(type: type),
      barrierDismissible: true,
    );
  }

  static Future<bool?> showClearCart() => show(CartConfirmType.clearCart);

  static Future<bool?> showRemoveItem() => show(CartConfirmType.removeItem);

  Color get _accent => AppColors.settingsDelete;

  Color get _iconBackground => switch (type) {
        CartConfirmType.clearCart => const Color(0xFFFFEBEE),
        CartConfirmType.removeItem => const Color(0xFFFFEBEE),
      };

  Widget get _leadingIcon => switch (type) {
        CartConfirmType.clearCart => CartIcon(size: 28.sp, color: _accent),
        CartConfirmType.removeItem => Icon(
          Icons.delete_outline_rounded,
          color: _accent,
          size: 28.sp,
        ),
      };

  String get _title => switch (type) {
        CartConfirmType.clearCart => 'أفراغ السلة',
        CartConfirmType.removeItem => 'حذف المنتج من السلة',
      };

  String get _message => 'هل أنت متأكد ؟';

  String get _confirmLabel => switch (type) {
        CartConfirmType.clearCart => 'أفراغ السلة',
        CartConfirmType.removeItem => 'حذف المنتج',
      };

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        insetPadding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52.w,
                height: 52.w,
                decoration: BoxDecoration(
                  color: _iconBackground,
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: _leadingIcon,
              ),
              SizedBox(height: 16.h),
              MyText(
                _title,
                fontSize: 20.sp,
                fontWeight: FontWeight.w800,
                color: _accent,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10.h),
              Text(
                _message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Expo Arabic',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48.h,
                      child: ElevatedButton(
                        onPressed: () => Get.back(result: true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                        child: MyText(
                          _confirmLabel,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: SizedBox(
                      height: 48.h,
                      child: OutlinedButton(
                        onPressed: () => Get.back(result: false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _accent,
                          side: BorderSide(color: _accent, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                        child: MyText(
                          'إلغاء',
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          color: _accent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
