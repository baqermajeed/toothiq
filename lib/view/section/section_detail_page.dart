import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../bindings/section_detail_binding.dart';
import '../../controller/section_detail_controller.dart';
import '../../model/category_model.dart';
import '../../utils/app_colors.dart';
import '../../widget/home/category_chip_widget.dart';
import '../../widget/search_filter_row.dart';
import '../../widget/section/brand_card_widget.dart';
import '../../widget/section/section_app_bar.dart';
import '../../widget/section/section_products_grid.dart';
import 'brand_products_page.dart';

class SectionDetailPage extends StatelessWidget {
  final CategoryModel category;

  const SectionDetailPage({super.key, required this.category});

  static void open(CategoryModel category) {
    Get.to(
      () => SectionDetailPage(category: category),
      binding: SectionDetailBinding(category: category),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<SectionDetailController>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: const SectionAppBar(title: 'أسم القسم'),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 8.h),
            _SectionFilterTabs(controller: ctrl),
            SizedBox(height: 12.h),
            Expanded(
              child: Obx(() {
                final tabIndex = ctrl.selectedTabIndex.value;
                if (tabIndex == 1) {
                  return _BrandsTabContent(controller: ctrl);
                }
                return SectionProductsGrid(
                  products: tabIndex == 2
                      ? ctrl.whiteningProducts
                      : ctrl.sectionProducts,
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionFilterTabs extends StatelessWidget {
  final SectionDetailController controller;

  const _SectionFilterTabs({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44.h,
      child: Obx(() {
        final selectedIndex = controller.selectedTabIndex.value;
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          itemCount: SectionDetailController.tabs.length,
          separatorBuilder: (context, index) => SizedBox(width: 10.w),
          itemBuilder: (context, index) {
            return CategoryChipWidget(
              label: SectionDetailController.tabs[index],
              isSelected: selectedIndex == index,
              onTap: () => controller.selectTab(index),
            );
          },
        );
      }),
    );
  }
}

class _BrandsTabContent extends StatelessWidget {
  final SectionDetailController controller;

  const _BrandsTabContent({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SearchFilterRow(
          controller: controller.brandSearchController,
          hintText: 'أبحث عن براند محدد ..',
          filterCircular: true,
        ),
        SizedBox(height: 14.h),
        Expanded(
          child: Obx(
            () => GridView.builder(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12.w,
                mainAxisSpacing: 12.h,
                childAspectRatio: 0.78,
              ),
              itemCount: controller.filteredBrands.length,
              itemBuilder: (context, index) {
                final brand = controller.filteredBrands[index];
                return BrandCardWidget(
                  brand: brand,
                  onTap: () => BrandProductsPage.open(brand),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
