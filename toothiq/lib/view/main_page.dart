import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../bindings/home_binding.dart';
import '../controller/app_update_controller.dart';
import '../controller/main_controller.dart';
import '../controller/orders_controller.dart';
import '../core/navigation/app_route_observer.dart';
import '../utils/app_colors.dart';
import '../widget/app_bottom_navigation.dart';
import 'categories/categories_page.dart';
import 'home/home_page.dart';
import 'orders/orders_page.dart';
import 'settings/settings_page.dart';
import 'stores/stores_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  /// يعيد تسجيل الـ controllers بعد Get.offAll
  static void open() {
    HomeBinding().dependencies();
    if (!Get.isRegistered<AppUpdateController>()) {
      Get.put(AppUpdateController(), permanent: true);
    } else {
      Get.find<AppUpdateController>().checkForUpdate();
    }
    Get.offAll(() => const MainPage());
  }

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with RouteAware {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) {
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _refreshOrdersIfVisible();
  }

  void _refreshOrdersIfVisible() {
    if (!Get.isRegistered<MainController>() ||
        !Get.isRegistered<OrdersController>()) {
      return;
    }
    if (Get.find<MainController>().currentIndex.value !=
        OrdersController.ordersTabIndex) {
      return;
    }
    Get.find<OrdersController>().refreshSilently();
  }

  @override
  Widget build(BuildContext context) {
    final main = Get.find<MainController>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Obx(
          () => IndexedStack(
            index: main.currentIndex.value,
            children: const [
              HomePage(),
              StoresPage(),
              CategoriesPage(),
              OrdersPage(),
              SettingsPage(),
            ],
          ),
        ),
        bottomNavigationBar: const AppBottomNavigation(),
      ),
    );
  }
}
