import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/edit_profile_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_spacing.dart';
import '../../widgets/common/app_text_field.dart';

/// مركز افتراضي للخريطة (بغداد) عند عدم وجود موقع محفوظ.
const double _defaultMapLat = 33.3152;
const double _defaultMapLng = 44.3661;

/// شاشة تعديل المعلومات الشخصية — الاسم، البريد، عنوان التوصيل (الموقع).
class EditProfileScreen extends GetView<EditProfileController> {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Obx(() {
      final user = Get.find<AuthController>().user.value;
      if (user == null) {
        return Scaffold(
          body: Center(
            child: Text(
              'يجب تسجيل الدخول',
              style: TextStyle(
                fontFamily: kFontFamilyCairo,
                fontSize: 16.sp,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        );
      }
      return Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          backgroundColor: colorScheme.surface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20.sp),
            onPressed: () => Get.back(),
          ),
          title: Text(
            'تعديل المعلومات الشخصية',
            style: TextStyle(
              fontFamily: kFontFamilyCairo,
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSpacing.verticalLg,
              AppTextField(
                controller: controller.nameController,
                hint: 'الاسم',
                textInputAction: TextInputAction.next,
              ),
              AppSpacing.verticalMd,
              Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text(
                  'رقم الهاتف (للعرض فقط)',
                  style: TextStyle(
                    fontFamily: kFontFamilyCairo,
                    fontSize: 14.sp,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
                ),
                child: Text(
                  user.phone,
                  style: TextStyle(
                    fontFamily: kFontFamilyCairo,
                    fontSize: 16.sp,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
              AppSpacing.verticalLg,
              Text(
                'عنوان التوصيل',
                style: TextStyle(
                  fontFamily: kFontFamilyCairo,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 8.h),
              Obx(() {
                final lat = controller.selectedLat.value;
                final lng = controller.selectedLng.value;
                final hasLocation = lat != null && lng != null;
                final mapReady = controller.mapReady.value;
                return Stack(
                  alignment: AlignmentDirectional.topEnd,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16.r),
                      child: SizedBox(
                        height: 200.h,
                        width: double.infinity,
                        child: mapReady
                            ? GoogleMap(
                                initialCameraPosition: CameraPosition(
                                  target: LatLng(
                                    lat ?? _defaultMapLat,
                                    lng ?? _defaultMapLng,
                                  ),
                                  zoom: hasLocation ? 15 : 10,
                                ),
                                markers: hasLocation
                                    ? {
                                        Marker(
                                          markerId: const MarkerId('delivery'),
                                          position: LatLng(lat, lng),
                                        ),
                                      }
                                    : {},
                                onTap: (LatLng position) async {
                                  await controller.setLocationFromMap(position.latitude, position.longitude);
                                },
                                myLocationButtonEnabled: false,
                                zoomControlsEnabled: false,
                              )
                            : ColoredBox(
                                color: colorScheme.surfaceContainerHighest,
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 32.w,
                                        height: 32.h,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                      SizedBox(height: 12.h),
                                      Text(
                                        'جاري تحميل الخريطة...',
                                        style: TextStyle(
                                          fontFamily: kFontFamilyCairo,
                                          fontSize: 14.sp,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(12.r),
                      child: Material(
                        color: colorScheme.surface.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(12.r),
                        child: IconButton(
                          icon: Icon(Icons.fullscreen_rounded, size: 24.sp),
                          onPressed: () async {
                            final result = await Get.toNamed(
                              '/full-screen-map',
                              arguments: {
                                'lat': controller.selectedLat.value ?? _defaultMapLat,
                                'lng': controller.selectedLng.value ?? _defaultMapLng,
                                'mode': 'pick',
                              },
                            );
                            if (result is LatLng) {
                              await controller.setLocationFromMap(result.latitude, result.longitude);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                );
              }),
              SizedBox(height: 12.h),
              Obx(() {
                final isLoading = controller.isGettingLocation.value;
                return SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: isLoading ? null : () => controller.getCurrentLocation(),
                    icon: isLoading
                        ? SizedBox(
                            width: 20.w,
                            height: 20.h,
                            child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primary),
                          )
                        : Icon(Icons.my_location_rounded, size: 20.sp, color: colorScheme.primary),
                    label: Text(
                      isLoading ? 'جاري الحصول على الموقع...' : 'استخدام موقعي الحالي',
                      style: TextStyle(
                        fontFamily: kFontFamilyCairo,
                        fontSize: 14.sp,
                        color: colorScheme.primary,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      side: BorderSide(color: colorScheme.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                    ),
                  ),
                );
              }),
              SizedBox(height: 8.h),
              Text(
                'انقر على الخريطة لتعيين عنوان التوصيل، أو استخدم «موقعي الحالي».',
                style: TextStyle(
                  fontFamily: kFontFamilyCairo,
                  fontSize: 12.sp,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              AppSpacing.verticalXl,
              Obx(() {
                final isSaving = controller.isSaving.value;
                return AppButton(
                  label: isSaving ? 'جاري الحفظ...' : 'حفظ',
                  onPressed: isSaving ? null : controller.save,
                );
              }),
            ],
          ),
        ),
      );
    });
  }
}
