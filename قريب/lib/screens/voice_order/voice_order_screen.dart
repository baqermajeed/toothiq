import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/voice_order_controller.dart';
import '../../core/config/api_config.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/dialogs/guest_register_dialog.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_spacing.dart';
import '../../widgets/common/hold_to_record_button.dart';

/// شاشة طلب الشراء بالمقطع الصوتي: تسجيل فقط، وعند النقر على إرسال يتوقف التسجيل ويُرسل الطلب.
class VoiceOrderScreen extends GetView<VoiceOrderController> {
  const VoiceOrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20.sp),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'طلب شراء بالمقطع الصوتي',
          style: TextStyle(
            fontFamily: kFontFamilyCairo,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Obx(() {
        if (controller.shopsLoading.value && controller.shops.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        final isVoiceOrderOnly = controller.isVoiceOrderOnlyZone.value;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!isVoiceOrderOnly) ...[
                _SectionTitle(title: 'اختر المحلات المستهدفة'),
                SizedBox(height: 8.h),
                Text(
                  'اختر المحلات التي تريد إرسال الطلب الصوتي إليها. سيُرسل الطلب إلى جميع المحلات المحددة.',
                  style: TextStyle(
                    fontFamily: kFontFamilyCairo,
                    fontSize: 14.sp,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 12.h),
                _ShopSelector(controller: controller),
                SizedBox(height: 24.h),
              ] else ...[
                Text(
                  'منطقتك تدعم فقط الطلبات الصوتية. سجّل طلبك وسنوصله للبيت.',
                  style: TextStyle(
                    fontFamily: kFontFamilyCairo,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20.h),
              ],
              _SectionTitle(title: 'سجّل المقطع الصوتي'),
              SizedBox(height: 8.h),
              Text(
                isVoiceOrderOnly
                    ? 'اضغط مع الاستمرار على الزر للتسجيل، وارفَع إصبعك لإيقاف التسجيل. سنستلم طلبك ونوصله إليك.'
                    : 'اضغط مع الاستمرار على الزر للتسجيل، وارفَع إصبعك لإيقاف التسجيل. يجب أن تكون المنتجات من ضمن المعروضة في التطبيق.',
                style: TextStyle(
                  fontFamily: kFontFamilyCairo,
                  fontSize: 14.sp,
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              if (!isVoiceOrderOnly)
                SizedBox(height: 8.h),
              if (!isVoiceOrderOnly)
                Text(
                  'لماذا الميكروفون؟ لتسجيل مقطع الطلب الصوتي وإرساله للمحلات المختارة فقط.',
                  style: TextStyle(
                    fontFamily: kFontFamilyCairo,
                    fontSize: 12.sp,
                    height: 1.35,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                  ),
                ),
              SizedBox(height: 20.h),
              _VoiceRecordSection(controller: controller),
              if (controller.errorMessage.value != null) ...[
                SizedBox(height: 8.h),
                Text(
                  controller.errorMessage.value!,
                  style: TextStyle(
                    fontFamily: kFontFamilyCairo,
                    fontSize: 13.sp,
                    color: colorScheme.error,
                  ),
                ),
              ],
              SizedBox(height: 24.h),
              AppButton(
                label: 'إرسال الطلب الصوتي',
                // minHeight: 52.h,
                loading: controller.isSubmitting.value || controller.isUploading.value,
                onPressed: () {
                  final auth = Get.find<AuthController>();
                  if (!auth.isAuthenticated) {
                    showGuestRegisterDialog().then((result) {
                      if (result != null) {
                        controller.submit(guestCredentials: result);
                      }
                    });
                  } else {
                    controller.submit();
                  }
                },
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      title,
      style: TextStyle(
        fontFamily: kFontFamilyCairo,
        fontSize: 16.sp,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
    );
  }
}

class _ShopSelector extends StatelessWidget {
  const _ShopSelector({required this.controller});

  final VoiceOrderController controller;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? colorScheme.surfaceContainerHighest : Colors.white;
    final borderColor = isDark ? colorScheme.outline.withValues(alpha: 0.3) : AppColors.border;

    return Obx(() {
      if (controller.shops.isEmpty) {
        return Container(
          padding: EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: borderColor),
          ),
          child: Text(
            'لا توجد محلات متاحة',
            style: TextStyle(
              fontFamily: kFontFamilyCairo,
              fontSize: 14.sp,
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        );
      }
      return Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (controller.selectedShops.isNotEmpty)
              Padding(
                padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 4.h),
                child: Text(
                  'تم اختيار ${controller.selectedShops.length} محل',
                  style: TextStyle(
                    fontFamily: kFontFamilyCairo,
                    fontSize: 13.sp,
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 240.h),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 8.h),
                itemCount: controller.shops.length,
                itemBuilder: (context, index) {
                  final shop = controller.shops[index];
                  final selected = controller.isShopSelected(shop);
                  final shopImageUrl = ApiConfig.shopImageUrl(shop.image);
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => controller.toggleShop(shop),
                      borderRadius: BorderRadius.circular(12.r),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                        child: Row(
                          children: [
                            Icon(
                              selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                              size: 24.sp,
                              color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                            ),
                            SizedBox(width: 12.w),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10.r),
                              child: SizedBox(
                                width: 40.w,
                                height: 40.h,
                                child: shopImageUrl != null && shopImageUrl.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: shopImageUrl,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) => Container(
                                          color: colorScheme.surfaceContainerHighest,
                                          alignment: Alignment.center,
                                          child: Text('🛒', style: TextStyle(fontSize: 20.sp)),
                                        ),
                                        errorWidget: (_, __, ___) => Container(
                                          color: colorScheme.surfaceContainerHighest,
                                          alignment: Alignment.center,
                                          child: Text('🛒', style: TextStyle(fontSize: 20.sp)),
                                        ),
                                      )
                                    : Container(
                                        color: colorScheme.surfaceContainerHighest,
                                        alignment: Alignment.center,
                                        child: Text('🛒', style: TextStyle(fontSize: 20.sp)),
                                      ),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    shop.name,
                                    style: TextStyle(
                                      fontFamily: kFontFamilyCairo,
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  if (shop.category.isNotEmpty)
                                    Text(
                                      shop.category,
                                      style: TextStyle(
                                        fontFamily: kFontFamilyCairo,
                                        fontSize: 12.sp,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _VoiceRecordSection extends StatelessWidget {
  const _VoiceRecordSection({required this.controller});

  final VoiceOrderController controller;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? colorScheme.surfaceContainerHighest : Colors.white;
    final borderColor = isDark ? colorScheme.outline.withValues(alpha: 0.3) : AppColors.border;

    return Obx(() {
      return Container(
        padding: EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (controller.audioPath.value == null || controller.isRecording.value)
              SizedBox(
                width: double.infinity,
                child: HoldToRecordButton(
                  isRecording: controller.isRecording.value,
                  onRecordingStart: controller.startRecording,
                  onRecordingStop: controller.stopRecording,
                  label: 'اضغط للتسجيل',
                  // minHeight: 52.h,
                ),
              )
            else ...[
              Row(
                children: [
                  Icon(Icons.check_circle_rounded, size: 20.sp, color: colorScheme.primary),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'يوجد تسجيل جاهز. يمكنك إرسال الطلب أو حذفه لتسجيل صوت آخر.',
                      style: TextStyle(
                        fontFamily: kFontFamilyCairo,
                        fontSize: 13.sp,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              TextButton.icon(
                onPressed: controller.removeAudio,
                icon: Icon(Icons.delete_outline_rounded, size: 20.sp, color: colorScheme.error),
                label: Text(
                  'حذف التسجيل وتسجيل جديد',
                  style: TextStyle(
                    fontFamily: kFontFamilyCairo,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.error,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
}
