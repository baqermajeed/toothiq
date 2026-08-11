import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controller/home_controller.dart';
import '../../utils/app_colors.dart';
import '../../widget/common/async_state_widgets.dart';
import '../../widget/home/product_card_widget.dart';
import '../../widget/section/section_app_bar.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  static void open() {
    Get.to(() => const FavoritesPage());
  }

  @override
  Widget build(BuildContext context) {
    final home = Get.find<HomeController>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: const SectionAppBar(title: 'المفضلات'),
        body: Obx(() {
          if (home.isLoading.value && home.products.isEmpty) {
            return const AppLoadingState();
          }

          if (home.loadError.value != null && home.products.isEmpty) {
            return AppErrorState(
              message: home.loadError.value!,
              onRetry: () => home.refresh(),
            );
          }

          final favorites = home.products.where((p) => p.isFavorite).toList();

          if (favorites.isEmpty) {
            return const AppEmptyState(
              title: 'لا توجد منتجات في المفضلة',
              subtitle: 'اضغط على القلب في أي منتج لإضافته هنا',
              icon: Icons.favorite_border_rounded,
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: home.refresh,
            child: GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12.w,
                mainAxisSpacing: 14.h,
                childAspectRatio: 0.55,
              ),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final product = favorites[index];
                return LayoutBuilder(
                  builder: (context, constraints) {
                    return ProductCardWidget(
                      product: product,
                      maxHeight: constraints.maxHeight,
                    );
                  },
                );
              },
            ),
          );
        }),
      ),
    );
  }
}
