import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controller/main_tab_controller.dart';
import '../../controller/session_controller.dart';
import '../../controller/shop_catalog_controller.dart';
import '../../controller/shop_orders_controller.dart';
import '../../controller/shop_products_controller.dart';
import '../../controller/shop_profile_controller.dart';
import '../../core/navigation/partner_notification_router.dart';
import '../../service_layer/services/order_service.dart';
import '../../service_layer/services/product_stock_cache.dart';
import '../../service_layer/services/shop_service.dart';
import '../../utils/app_colors.dart';
import '../../widget/my_text.dart';
import 'shop_home_page.dart';
import 'shop_orders_page.dart';
import 'shop_products_page.dart';
import 'shop_settings_page.dart';

class ShopMainPage extends StatelessWidget {
  const ShopMainPage({super.key});

  static void open() {
    Get.offAll(() => const ShopMainPage());
  }

  @override
  Widget build(BuildContext context) {
    final tabs = Get.put(MainTabController(), tag: 'shop');
    final session = Get.find<SessionController>();
    final orderService = Get.find<OrderService>();
    final shopService = Get.find<ShopService>();

    Get.put(
      ShopOrdersController(orderService: orderService, session: session),
    );
    Get.put(
      ShopProductsController(
        shopService: shopService,
        session: session,
        stockCache: Get.find<ProductStockCache>(),
      ),
    );
    Get.put(
      ShopProfileController(shopService: shopService, session: session),
    );
    Get.put(
      ShopCatalogController(shopService: shopService, session: session),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      PartnerNotificationRouter.consumePending();
    });

    const pages = [
      ShopHomePage(),
      ShopOrdersPage(),
      ShopProductsPage(),
      ShopSettingsPage(),
    ];

    return Obx(
      () => Scaffold(
        body: IndexedStack(index: tabs.currentIndex.value, children: pages),
        bottomNavigationBar: _BottomNav(
          index: tabs.currentIndex.value,
          onChanged: tabs.changeTab,
          items: const [
            (Icons.dashboard_outlined, Icons.dashboard, 'الرئيسية'),
            (Icons.receipt_long_outlined, Icons.receipt_long, 'الطلبات'),
            (Icons.inventory_2_outlined, Icons.inventory_2, 'المنتجات'),
            (Icons.settings_outlined, Icons.settings, 'الإعدادات'),
          ],
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.index,
    required this.onChanged,
    required this.items,
  });

  final int index;
  final ValueChanged<int> onChanged;
  final List<(IconData, IconData, String)> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bottomNavBackground,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var i = 0; i < items.length; i++)
                _NavItem(
                  icon: items[i].$1,
                  activeIcon: items[i].$2,
                  label: items[i].$3,
                  selected: index == i,
                  onTap: () => onChanged(i),
                ),
            ],
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
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? activeIcon : icon, color: color, size: 22.sp),
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
