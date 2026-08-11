import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

import '../../controller/session_controller.dart';
import '../../core/api/api_exception.dart';
import '../../service_layer/services/user_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/location_helper.dart';
import '../../view/map/map_pick_page.dart';
import '../../view/settings/saved_addresses_page.dart';
import '../common/app_toast.dart';
import 'location_permission_denied_dialog.dart';

/// دايلوغ يطلب تحديد موقع التوصيل قبل إتمام الطلب — مثل قريب.
class DeliveryLocationRequiredDialog extends StatefulWidget {
  const DeliveryLocationRequiredDialog({super.key});

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

  Future<void> _saveLocation(
    double lat,
    double lng, {
    bool closeDialog = true,
  }) async {
    final session = Get.find<SessionController>();
    if (!session.isAuthenticated) {
      setState(() => _errorMessage = 'يجب تسجيل الدخول');
      return;
    }

    final updated = await Get.find<UserService>().updateLocation(lat, lng);
    session.user.value = updated;
    if (!mounted) return;
    if (closeDialog && Get.isDialogOpen == true) {
      Get.back();
    }
    AppToast.show(
      'تم تحديد الموقع',
      'تم حفظ موقع التوصيل. يمكنك إتمام الطلب الآن.',
      type: ToastType.success,
    );
  }

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
          _errorMessage =
              'لم يتم الحصول على الموقع. تأكد من تفعيل خدمة الموقع.';
        });
        return;
      }
      final lat = coords[1];
      final lng = coords[0];
      if (!IraqLocationBounds.contains(lat, lng)) {
        setState(() {
          _errorMessage =
              'الموقع المستلم يبدو خارج العراق. استخدم الخريطة أو ابحث عن مدينتك.';
        });
        return;
      }
      await _saveLocation(lat, lng);
    } on ApiException catch (error) {
      setState(() => _errorMessage = error.message);
    } catch (_) {
      setState(() => _errorMessage = 'حدث خطأ، حاول مرة أخرى');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openMap() async {
    Get.back();
    final result = await MapPickPage.open();
    if (result == null) return;
    try {
      await _saveLocation(result.lat, result.lng, closeDialog: false);
    } on ApiException catch (error) {
      AppToast.show('فشل حفظ الموقع', error.message, type: ToastType.error);
    } catch (_) {
      AppToast.show(
        'فشل حفظ الموقع',
        'حدث خطأ، حاول مرة أخرى',
        type: ToastType.error,
      );
    }
  }

  void _openSavedAddresses() {
    Get.back();
    SavedAddressesPage.open();
  }

  @override
  Widget build(BuildContext context) {
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
              color: AppColors.primaryLight.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_on_rounded,
              size: 48.sp,
              color: AppColors.primaryDark,
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            'تحديد موقع التوصيل',
            style: TextStyle(
              fontFamily: 'Expo Arabic',
              fontSize: 22.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12.h),
          Text(
            'يجب تحديد موقعك حتى نتمكن من توصيل الطلب إليك. اختر أحد الخيارات أدناه.',
            style: TextStyle(
              fontFamily: 'Expo Arabic',
              fontSize: 15.sp,
              height: 1.5,
              color: AppColors.textSecondary,
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
                  fontFamily: 'Expo Arabic',
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
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(Icons.my_location_rounded, size: 22.sp),
              label: Text(
                _isLoading ? 'جاري تحديد الموقع...' : 'استخدام موقعي الحالي',
                style: TextStyle(
                  fontFamily: 'Expo Arabic',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                foregroundColor: Colors.white,
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
              onPressed: _isLoading ? null : _openMap,
              icon: Icon(Icons.map_rounded, size: 22.sp, color: AppColors.primary),
              label: Text(
                'تعيين من الخريطة',
                style: TextStyle(
                  fontFamily: 'Expo Arabic',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                side: const BorderSide(color: AppColors.primary),
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
              onPressed: _isLoading ? null : _openSavedAddresses,
              icon: Icon(Icons.home_work_outlined, size: 22.sp, color: AppColors.primary),
              label: Text(
                'عناوين التوصيل المحفوظة',
                style: TextStyle(
                  fontFamily: 'Expo Arabic',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                side: const BorderSide(color: AppColors.primary),
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
                fontFamily: 'Expo Arabic',
                fontSize: 15.sp,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
