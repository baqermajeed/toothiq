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

  static const routeName = '/main';

  /// يعيد تسجيل الـ controllers بعد Get.offAll
  static void open() {
    HomeBinding().dependencies();
    if (!Get.isRegistered<AppUpdateController>()) {
      Get.put(AppUpdateController(), permanent: true);
    }

    // لا تفتح دايلوغ التحديث قبل اكتمال الانتقال — يسبب ANR مع Get.offAll.
    Get.offAll(() => const MainPage(), routeName: routeName);

    Future<void>.delayed(const Duration(milliseconds: 350), () {
      if (!Get.isRegistered<AppUpdateController>()) return;
      Get.find<AppUpdateController>().checkForUpdate();
    });
  }

  /// العودة للصفحة الرئيسية بعد إتمام الطلب دون إعادة إنشائها.
  static void returnFromCheckout() {
    if (Get.isRegistered<MainController>()) {
      Get.find<MainController>().changeTab(OrdersController.ordersTabIndex);
    }
    if (Get.isRegistered<OrdersController>()) {
      Get.find<OrdersController>().refreshSilently();
    }

    final nav = Get.key.currentState;
    if (nav == null) return;

    var pops = 0;
    while (nav.canPop() && pops < 4) {
      if (Get.rawRoute?.settings.name == routeName) return;
      Get.back();
      pops++;
      if (Get.rawRoute?.settings.name == routeName) return;
    }
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
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        extendBody: true,
        body: Stack(
          children: [
            Obx(
              () => IndexedStack(
                index: main.currentIndex.value,
                children: const [
                  StoresPage(),
                  CategoriesPage(),
                  HomePage(),
                  OrdersPage(),
                  SettingsPage(),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: AppBottomNavMetrics.bottomMargin() + bottomInset,
              child: const Center(child: AppBottomNavigation()),
            ),
          ],
        ),
      ),
    );
  }
}
