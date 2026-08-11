import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../core/errors/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// دايلوغ يوضح أن موقع المستخدم غير مدعوم للتوصيل حالياً — يُعرض عند إتمام الطلب
/// أو عند فشل الطلب بسبب عدم وجود منطقة توصيل تغطي العنوان.
class ZoneNotSupportedDialog extends StatelessWidget {
  const ZoneNotSupportedDialog({
    super.key,
    this.subtitle,
  });

  /// نص إضافي تحت الوصف الأساسي (مثلاً رسالة الـ API).
  final String? subtitle;

  /// يعرض الدايلوغ. [subtitle] اختياري للتفاصيل الإضافية.
  static void show({String? subtitle}) {
    Get.dialog(
      ZoneNotSupportedDialog(subtitle: subtitle),
      barrierDismissible: false,
    );
  }

  /// يُرجع true إن كانت رسالة الخطأ تشير إلى أن الموقع خارج منطقة التوصيل.
  static bool isZoneError(ApiException e) {
    final msg = e.message.toLowerCase();
    return msg.contains('outside the delivery zone') ||
        msg.contains('not in a voice-order-only zone');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.r),
      ),
      contentPadding: EdgeInsets.fromLTRB(24.w, 28.h, 24.w, 24.h),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                  .withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_off_rounded,
              size: 48.sp,
              color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            'موقعك غير مدعوم حالياً',
            style: TextStyle(
              fontFamily: kFontFamilyCairo,
              fontSize: 22.sp,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12.h),
          Text(
            'عنوان التوصيل الذي اخترته يقع خارج مناطق التوصيل المتاحة. سنضيف تغطية لمنطقتك قريباً.',
            style: TextStyle(
              fontFamily: kFontFamilyCairo,
              fontSize: 15.sp,
              height: 1.5,
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Text(
              subtitle!,
              style: TextStyle(
                fontFamily: kFontFamilyCairo,
                fontSize: 14.sp,
                height: 1.4,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.9),
              ),
              textAlign: TextAlign.center,
            ),
          ],
          SizedBox(height: 24.h),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Get.back(),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                foregroundColor: AppColors.primaryLight,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              child: Text(
                'حسناً',
                style: TextStyle(
                  fontFamily: kFontFamilyCairo,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
