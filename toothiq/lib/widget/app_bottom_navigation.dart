import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controller/main_controller.dart';
import '../utils/app_colors.dart';
import 'my_text.dart';

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({super.key});

  static const List<_NavItemData> _items = [
    _NavItemData(icon: Icons.home_rounded, label: 'الرئيسية'),
    _NavItemData(icon: Icons.storefront_outlined, label: 'المتاجر'),
    _NavItemData(icon: Icons.grid_view_rounded, label: 'الأقسام'),
    _NavItemData(icon: Icons.inventory_2_outlined, label: 'طلباتك'),
    _NavItemData(icon: Icons.settings_outlined, label: 'الأعدادات'),
  ];

  @override
  Widget build(BuildContext context) {
    final main = Get.find<MainController>();

    return Obx(
      () => Container(
        decoration: BoxDecoration(
          color: AppColors.bottomNavBackground,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28.r),
            topRight: Radius.circular(28.r),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(8.w, 12.h, 8.w, 8.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_items.length, (index) {
                final item = _items[index];
                final isSelected = main.currentIndex.value == index;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => main.changeTab(index),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.icon,
                          size: 24.sp,
                          color: isSelected
                              ? AppColors.bottomNavActive
                              : AppColors.bottomNavInactive,
                        ),
                        SizedBox(height: 4.h),
                        MyText(
                          item.label,
                          fontSize: 11.sp,
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected
                              ? AppColors.bottomNavActive
                              : AppColors.bottomNavInactive,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final String label;

  const _NavItemData({required this.icon, required this.label});
}
