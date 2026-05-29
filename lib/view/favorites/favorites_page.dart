import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controller/home_controller.dart';
import '../../utils/app_colors.dart';
import '../../widget/home/product_card_widget.dart';
import '../../widget/my_text.dart';
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
          final favorites =
              home.products.where((p) => p.isFavorite).toList();

          if (favorites.isEmpty) {
            return const _FavoritesEmptyState();
          }

          return GridView.builder(
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
          );
        }),
      ),
    );
  }
}

class _FavoritesEmptyState extends StatelessWidget {
  const _FavoritesEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border_rounded,
              size: 64.sp,
              color: AppColors.textLight,
            ),
            SizedBox(height: 16.h),
            MyText(
              'لا توجد منتجات في المفضلة',
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            MyText(
              'اضغط على القلب في أي منتج لإضافته هنا',
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.textLight,
              textAlign: TextAlign.center,
              height: 1.5,
            ),
          ],
        ),
      ),
    );
  }
}
