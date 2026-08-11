import 'dart:math' show pi;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controller/settings_controller.dart';
import '../../model/settings_menu_item.dart';
import '../../utils/app_colors.dart';

class SettingsMenuTile extends StatelessWidget {
  final SettingsMenuItem item;
  final SettingsController controller;
  final VoidCallback? onTap;

  const SettingsMenuTile({
    super.key,
    required this.item,
    required this.controller,
    this.onTap,
  });

  bool get _isLogout => item.id == 'logout';
  bool get _isDelete => item.id == 'delete_account';

  Color get _titleColor {
    if (item.titleColor != null) return item.titleColor!;
    if (_isLogout) return AppColors.settingsLogout;
    if (_isDelete) return AppColors.settingsDelete;
    return AppColors.textPrimary;
  }

  Color get _iconColor {
    if (item.iconColor != null) return item.iconColor!;
    if (_isLogout) return AppColors.settingsLogout;
    if (_isDelete) return AppColors.settingsDelete;
    return AppColors.settingsIcon;
  }

  @override
  Widget build(BuildContext context) {
    final isToggle = item.kind == SettingsItemKind.toggle;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.settingsCardBorder, width: 1),
        boxShadow: const [
          BoxShadow(
            color: AppColors.orderCardShadow,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isToggle ? null : onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
            child: Row(
            children: [
              Icon(item.icon, color: _iconColor, size: 24.sp),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  item.title,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: 'Expo Arabic',
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: _titleColor,
                    height: 1.3,
                  ),
                ),
              ),
              if (isToggle)
                Obx(
                  () => _SettingsSwitch(
                    value: controller.notificationsEnabled.value,
                    onChanged: controller.toggleNotifications,
                  ),
                )
              else
                Transform.rotate(
                  angle: pi,
                  child: Icon(
                    Icons.chevron_left,
                    color: AppColors.textLight,
                    size: 24.sp,
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}

class _SettingsSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitch({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48.w,
      height: 28.h,
      child: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: Colors.white,
        activeTrackColor: AppColors.bottomNavBackground,
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: AppColors.indicatorInactive,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
