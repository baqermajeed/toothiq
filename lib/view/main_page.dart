import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/main_controller.dart';
import '../utils/app_colors.dart';
import '../widget/app_bottom_navigation.dart';
import 'categories/categories_page.dart';
import 'home/home_page.dart';
import 'orders/orders_page.dart';
import 'settings/settings_page.dart';
import 'stores/stores_page.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

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
