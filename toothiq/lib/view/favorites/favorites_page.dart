import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../service_layer/services/favorites_service.dart';
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
    final favorites = Get.find<FavoritesService>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: const SectionAppBar(title: 'المفضلات'),
        body: Obx(() {
          final items = favorites.favoriteProducts;

          if (items.isEmpty) {
            return const AppEmptyState(
              title: 'لا توجد منتجات في المفضلة',
              subtitle: 'اضغط على القلب في أي منتج لإضافته هنا',
              icon: Icons.favorite_border_rounded,
            );
          }

          return GridView.builder(
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
            itemCount: items.length,
            itemBuilder: (context, index) {
              final product = items[index];
              return ProductCardWidget(product: product);
            },
          );
        }),
      ),
    );
  }
}
