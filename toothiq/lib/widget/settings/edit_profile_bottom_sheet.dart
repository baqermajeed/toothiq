import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controller/edit_profile_controller.dart';
import '../../utils/app_colors.dart';
import '../my_text.dart';
import 'settings_labeled_field.dart';

class EditProfileBottomSheet extends StatefulWidget {
  const EditProfileBottomSheet({super.key});

  static Future<void> show() {
    Get.put(EditProfileController());
    return Get.bottomSheet(
      const EditProfileBottomSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
    ).whenComplete(() {
      if (Get.isRegistered<EditProfileController>()) {
        Get.delete<EditProfileController>();
      }
    });
  }

  @override
  State<EditProfileBottomSheet> createState() => _EditProfileBottomSheetState();
}

class _EditProfileBottomSheetState extends State<EditProfileBottomSheet> {
  final _scrollController = ScrollController();
  final _usernameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _clinicFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    for (final node in [_usernameFocus, _phoneFocus, _clinicFocus]) {
      node.addListener(() {
        if (node.hasFocus) _scrollWhenFieldFocused(node);
      });
    }
  }

  void _scrollWhenFieldFocused(FocusNode node) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final target = switch (node) {
        _ when identical(node, _phoneFocus) => 200.h,
        _ when identical(node, _clinicFocus) => 340.h,
        _ => 0.0,
      };
      _scrollController.animateTo(
        target.clamp(0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _usernameFocus.dispose();
    _phoneFocus.dispose();
    _clinicFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<EditProfileController>();
    final media = MediaQuery.of(context);
    final keyboardHeight = media.viewInsets.bottom;
    final maxSheetHeight = media.size.height * 0.92 - keyboardHeight;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          constraints: BoxConstraints(maxHeight: maxSheetHeight),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
          ),
          child: SingleChildScrollView(
            controller: _scrollController,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: AppColors.indicatorInactive,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                SizedBox(height: 16.h),
                MyText(
                  'تعديل معلوماتك',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20.h),
                _EditProfileAvatar(onTap: ctrl.onPickPhoto),
                SizedBox(height: 24.h),
                SettingsLabeledField(
                  label: 'أسم المستخدم',
                  hint: 'أكتب أسم المستخدم',
                  controller: ctrl.usernameController,
                  focusNode: _usernameFocus,
                ),
                SizedBox(height: 18.h),
                SettingsLabeledField(
                  label: 'رقم الهاتف',
                  hint: 'أكتب رقم هاتفك',
                  controller: ctrl.phoneController,
                  focusNode: _phoneFocus,
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: 18.h),
                SettingsLabeledField(
                  label: 'أسم العيادة ( أختياري )',
                  hint: 'أكتب أسم عيادتك',
                  controller: ctrl.clinicController,
                  focusNode: _clinicFocus,
                ),
                SizedBox(height: 28.h),
                _EditProfileActions(controller: ctrl),
                SizedBox(height: keyboardHeight > 0 ? 8.h : 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EditProfileAvatar extends StatelessWidget {
  final VoidCallback onTap;

  const _EditProfileAvatar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 108.w,
        height: 108.w,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 108.w,
              height: 108.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cardPlaceholder,
                border: Border.all(color: AppColors.settingsCardBorder),
              ),
              child: Icon(
                Icons.person_rounded,
                size: 48.sp,
                color: AppColors.settingsIcon,
              ),
            ),
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.orderCardShadow,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.camera_alt_outlined,
                size: 22.sp,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditProfileActions extends StatelessWidget {
  final EditProfileController controller;

  const _EditProfileActions({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        height: 52.h,
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: AppColors.editProfileActionsBg,
          borderRadius: BorderRadius.circular(28.r),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: SizedBox(
                height: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.isSaving.value ? null : controller.save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.editProfilePrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                  ),
                  child: controller.isSaving.value
                      ? SizedBox(
                          width: 18.w,
                          height: 18.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : MyText(
                          'تعديل المعلومات',
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                ),
              ),
            ),
            SizedBox(width: 4.w),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: double.infinity,
                child: TextButton(
                  onPressed: controller.isSaving.value ? null : controller.cancel,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                  ),
                  child: MyText(
                    'الغاء',
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
