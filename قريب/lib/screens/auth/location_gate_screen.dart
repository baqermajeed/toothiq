import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controllers/location_gate_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_spacing.dart';
import '../../widgets/common/auth_header.dart';
import '../../widgets/common/location_request_card.dart';

/// شاشة طلب الموقع عند فتح التطبيق كضيف — قبل عرض الواجهة الرئيسية.
/// تصميم عصري: خلفية متدرجة، بطاقة محتوى، أيقونة موقع بارزة.
class LocationGateScreen extends GetView<LocationGateController> {
  const LocationGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    AppColors.surfaceDark,
                    AppColors.surfaceDark.withValues(alpha: 0.98),
                    AppColors.borderDark.withValues(alpha: 0.6),
                  ]
                : [
                    AppColors.surface,
                    AppColors.primaryLight.withValues(alpha: 0.25),
                    AppColors.primaryLight.withValues(alpha: 0.12),
                  ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppSpacing.verticalLg,
                const AuthHeader(
                  logoAssetPath: 'assets/logo.png',
                ),
                AppSpacing.verticalXl,
                LocationRequestContentCard(
                  isDark: isDark,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LocationRequestIconArea(colorScheme: colorScheme),
                      AppSpacing.verticalLg,
                      Text(
                        'أضف موقعك',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: kFontFamilyCairo,
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.primaryDark,
                        ),
                      ),
                      AppSpacing.verticalSm,
                      Text(
                        'أضف موقعك لعرض المحلات القريبة منك والتي تقدم التوصيل لمنطقتك',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: kFontFamilyCairo,
                          fontSize: 15.sp,
                          height: 1.45,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                        ),
                      ),
                      AppSpacing.verticalSm,
                      // Text(
                      //   'لماذا نطلب الموقع؟ نستخدم موقعك الحالي فقط لعرض المحلات التي تخدم منطقتك وتحقق من إمكانية التوصيل إليك.',
                      //   textAlign: TextAlign.center,
                      //   style: TextStyle(
                      //     fontFamily: kFontFamilyCairo,
                      //     fontSize: 13.sp,
                      //     height: 1.5,
                      //     color: (isDark
                      //             ? AppColors.textSecondaryDark
                      //             : AppColors.textSecondary)
                      //         .withValues(alpha: 0.85),
                      //   ),
                      // ),
                      AppSpacing.verticalXl,
                      Obx(() {
                        final msg = controller.errorMessage.value;
                        if (msg == null) return const SizedBox.shrink();
                        return Padding(
                          padding: EdgeInsets.only(bottom: 0),
                          child: Container(
                            
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(12.r),
                            ),
                            child: Text(
                              msg,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: kFontFamilyCairo,
                                color: AppColors.error,
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                        );
                      }),
                      Obx(() => AppButton(
                            label: controller.isLoading.value
                                ? 'جاري تحديد الموقع...'
                                : 'استخدام موقعي الحالي',
                            loading: controller.isLoading.value,
                            onPressed: controller.isLoading.value
                                ? null
                                : controller.useCurrentLocation,
                          )),
                      AppSpacing.verticalMd,
                      Center(
                        child: TextButton(
                          onPressed: controller.skip,
                          style: TextButton.styleFrom(
                            foregroundColor: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary,
                          ),
                          child: Text(
                            'تخطي — سأضيفه لاحقاً',
                            style: TextStyle(
                              fontFamily: kFontFamilyCairo,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.verticalXxl,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
