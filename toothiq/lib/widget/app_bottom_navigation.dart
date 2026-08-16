import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controller/main_controller.dart';
import '../utils/app_colors.dart';
import 'my_text.dart';

/// أبعاد شريط التنقل العائم (مثل Art Inspiration)
abstract final class AppBottomNavMetrics {
  static double width() => 360.w;
  static double height() => 64.h;
  static double radius() => 40.r;
  static double horizontalMargin() => 16.5.w;
  static double bottomMargin() => 16.h;

  /// أزرار النظام / الـ gesture — يختلف بين الأجهزة لذا نأخذ الأكبر.
  static double systemBottomInset(BuildContext context) {
    final mq = MediaQuery.of(context);
    return math.max(mq.padding.bottom, mq.viewPadding.bottom);
  }

  static double barBottomOffset(BuildContext context) {
    return bottomMargin() + systemBottomInset(context);
  }

  /// ارتفاع محجوز فوق الشريط العائم + ناف بار النظام حتى لا تُغطى آخر عناصر القائمة.
  static double contentBottomPadding(BuildContext context) {
    return height() + bottomMargin() + 12.h + systemBottomInset(context);
  }
}

/// شريط التنقل السفلي العائم بزجاج ضبابي
class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({super.key});

  static const List<_NavItemData> _items = [
    _NavItemData(icon: Icons.storefront_outlined, label: 'المتاجر'),
    _NavItemData(icon: Icons.grid_view_rounded, label: 'الأقسام'),
    _NavItemData(icon: Icons.home_rounded, label: 'الرئيسية'),
    _NavItemData(icon: Icons.inventory_2_outlined, label: 'طلباتك'),
    _NavItemData(icon: Icons.settings_outlined, label: 'الأعدادات'),
  ];

  @override
  Widget build(BuildContext context) {
    final main = Get.find<MainController>();

    return Obx(
      () => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppBottomNavMetrics.radius()),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppBottomNavMetrics.radius()),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              width: AppBottomNavMetrics.width(),
              height: AppBottomNavMetrics.height(),
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius:
                    BorderRadius.circular(AppBottomNavMetrics.radius()),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_items.length, (index) {
                  final item = _items[index];
                  final isSelected = main.currentIndex.value == index;
                  final color = isSelected
                      ? AppColors.primary
                      : AppColors.bottomNavInactive;

                  return GestureDetector(
                    onTap: () => main.changeTab(index),
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      width: 58.w,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(item.icon, size: 22.sp, color: color),
                          SizedBox(height: 2.h),
                          MyText(
                            item.label,
                            fontSize: 11.sp,
                            fontWeight:
                                isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: color,
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
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final String label;

  const _NavItemData({required this.icon, required this.label});
}
