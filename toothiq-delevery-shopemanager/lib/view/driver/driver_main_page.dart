import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controller/driver_orders_controller.dart';
import '../../controller/main_tab_controller.dart';
import '../../service_layer/services/driver_tracking_socket_service.dart';
import '../../service_layer/services/order_service.dart';
import '../../utils/app_colors.dart';
import '../../widget/my_text.dart';
import 'driver_orders_page.dart';
import 'driver_settings_page.dart';
import 'driver_wallet_page.dart';

class DriverMainPage extends StatelessWidget {
  const DriverMainPage({super.key});

  static void open() {
    Get.offAll(() => const DriverMainPage());
  }

  @override
  Widget build(BuildContext context) {
    final tabs = Get.put(MainTabController(), tag: 'driver');
    Get.put(
      DriverOrdersController(
        orderService: Get.find<OrderService>(),
        socketService: Get.find<DriverTrackingSocketService>(),
      ),
    );

    const pages = [
      DriverOrdersPage(),
      DriverWalletPage(),
      DriverSettingsPage(),
    ];

    return Obx(
      () => Scaffold(
        body: IndexedStack(index: tabs.currentIndex.value, children: pages),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: AppColors.bottomNavBackground,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 12.r,
                offset: Offset(0, -2.h),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    icon: Icons.receipt_long_outlined,
                    activeIcon: Icons.receipt_long,
                    label: 'الطلبات',
                    selected: tabs.currentIndex.value == 0,
                    onTap: () => tabs.changeTab(0),
                  ),
                  _NavItem(
                    icon: Icons.account_balance_wallet_outlined,
                    activeIcon: Icons.account_balance_wallet,
                    label: 'المحفظة',
                    selected: tabs.currentIndex.value == 1,
                    onTap: () => tabs.changeTab(1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color =
        selected ? AppColors.bottomNavActive : AppColors.bottomNavInactive;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 6.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? activeIcon : icon, color: color, size: 24.sp),
            SizedBox(height: 4.h),
            MyText(
              label,
              fontSize: 11.sp,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}
