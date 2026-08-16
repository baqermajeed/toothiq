import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controller/home_controller.dart';
import '../../utils/app_colors.dart';
import '../../widget/app_bottom_navigation.dart';
import '../../widget/common/async_state_widgets.dart';
import '../../widget/main_app_bar.dart';
import '../../widget/section/brand_card_widget.dart';
import '../section/brand_products_page.dart';

class BrandsPage extends StatelessWidget {
  const BrandsPage({super.key});

  static void open() {
    Get.to(() => const BrandsPage());
  }

  @override
  Widget build(BuildContext context) {
    final home = Get.find<HomeController>();
    final topInset =
        MediaQuery.paddingOf(context).top + MainAppBar.toolbarHeight();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        extendBodyBehindAppBar: true,
        appBar: const MainAppBar(title: 'برانداتنا'),
        body: Obx(() {
          final brands = home.brands;
          if (brands.isEmpty) {
            return Padding(
              padding: EdgeInsets.only(top: topInset),
              child: const AppEmptyState(title: 'لا توجد براندات حالياً'),
            );
          }

          return GridView.builder(
            clipBehavior: Clip.none,
            padding: EdgeInsets.fromLTRB(
              16.w,
              topInset + 12.h,
              16.w,
              AppBottomNavMetrics.floatingBarReservedHeight.h,
            ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.h,
              childAspectRatio: 1.11,
            ),
            itemCount: brands.length,
            itemBuilder: (context, index) {
              final brand = brands[index];
              return BrandCardWidget(
                brand: brand,
                onTap: () => BrandProductsPage.openFromHome(brand),
              );
            },
          );
        }),
      ),
    );
  }
}
