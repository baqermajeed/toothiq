import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

import '../../core/errors/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../utils/location_helper.dart';
import '../../controllers/auth_controller.dart';
import '../common/app_toast.dart';
import 'location_permission_denied_dialog.dart';

/// دايلوغ يوضح للمستخدم أنه يجب تحديد موقعه لتوصيل الطلب، مع أزرار لتعيين الموقع
/// مباشرة: استخدام الموقع الحالي أو الذهاب لتعيين العنوان من الخريطة.
class DeliveryLocationRequiredDialog extends StatefulWidget {
  const DeliveryLocationRequiredDialog({super.key});

  /// يعرض الدايلوغ. يُستخدم عند محاولة إتمام الطلب دون وجود عنوان توصيل.
  static void show() {
    Get.dialog(
      const DeliveryLocationRequiredDialog(),
      barrierDismissible: false,
    );
  }

  @override
  State<DeliveryLocationRequiredDialog> createState() =>
      _DeliveryLocationRequiredDialogState();
}

class _DeliveryLocationRequiredDialogState
    extends State<DeliveryLocationRequiredDialog> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _useCurrentLocation() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final coords = await requestAndGetLocation();
      if (coords == null || coords.length < 2) {
        final permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          if (mounted) Get.back();
          LocationPermissionDeniedDialog.show();
          return;
        }
        setState(() {
          _errorMessage = 'لم يتم الحصول على الموقع. تأكد من تفعيل خدمة الموقع.';
        });
        return;
      }
      final auth = Get.find<AuthController>();
      final user = auth.user.value;
      if (user == null) {
        setState(() => _errorMessage = 'يجب تسجيل الدخول');
        return;
      }
      final updated = await auth.apiClient.updateMe(
        name: user.name,
        location: coords,
      );
      auth.user.value = updated;
      if (mounted) Get.back();
      AppToast.show(
        'تم تحديد الموقع',
        'تم حفظ عنوان التوصيل. يمكنك إتمام الطلب الآن.',
        type: ToastType.success,
      );
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = 'حدث خطأ، حاول مرة أخرى');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openEditProfile() {
    Get.back();
    Get.toNamed('/edit-profile');
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
              Icons.location_on_rounded,
              size: 48.sp,
              color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            'تحديد موقع التوصيل',
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
            'يجب تحديد موقعك الحالي حتى نتمكن من توصيل الطلب إليك. اختر أحد الخيارين أدناه دون الحاجة للخروج من الصفحة.',
            style: TextStyle(
              fontFamily: kFontFamilyCairo,
              fontSize: 15.sp,
              height: 1.5,
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (_errorMessage != null) ...[
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(
                  fontFamily: kFontFamilyCairo,
                  fontSize: 13.sp,
                  color: AppColors.error,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          SizedBox(height: 24.h),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isLoading ? null : _useCurrentLocation,
              icon: _isLoading
                  ? SizedBox(
                      width: 22.w,
                      height: 22.h,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryLight,
                      ),
                    )
                  : Icon(Icons.my_location_rounded, size: 22.sp),
              label: Text(
                _isLoading ? 'جاري تحديد الموقع...' : 'استخدام موقعي الحالي',
                style: TextStyle(
                  fontFamily: kFontFamilyCairo,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                foregroundColor: AppColors.primaryLight,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isLoading ? null : _openEditProfile,
              icon: Icon(Icons.map_rounded, size: 22.sp, color: colorScheme.primary),
              label: Text(
                'تعيين من الخريطة',
                style: TextStyle(
                  fontFamily: kFontFamilyCairo,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                side: BorderSide(color: colorScheme.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
            ),
          ),
          SizedBox(height: 8.h),
          TextButton(
            onPressed: _isLoading ? null : () => Get.back(),
            child: Text(
              'لاحقاً',
              style: TextStyle(
                fontFamily: kFontFamilyCairo,
                fontSize: 15.sp,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
