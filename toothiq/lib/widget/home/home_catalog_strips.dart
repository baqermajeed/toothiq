import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controller/main_controller.dart';
import '../../model/brand_model.dart';
import '../../model/category_model.dart';
import '../../utils/app_colors.dart';
import '../../view/brands/brands_page.dart';
import '../../view/section/brand_products_page.dart';
import '../../view/section/section_detail_page.dart';
import '../app_image.dart';
import '../categories/category_icon_widget.dart';
import '../my_text.dart';
import 'home_catalog_strips_metrics.dart';

/// صفوف أفقية للأقسام ثم البراندات أسفل السلايدر
class HomeCatalogStrips extends StatelessWidget {
  const HomeCatalogStrips({
    super.key,
    required this.categories,
    required this.brands,
  });

  final List<CategoryModel> categories;
  final List<BrandModel> brands;

  void _openCategoriesTab() {
    if (Get.isRegistered<MainController>()) {
      Get.find<MainController>().changeTab(1);
    }
  }

  void _openBrandsPage() => BrandsPage.open();

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty && brands.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (categories.isNotEmpty)
          _CatalogStrip(
            title: 'الأقسام',
            titleTop: HomeCatalogStripsMetrics.titleTop(),
            listHeight: HomeCatalogStripsMetrics.categoryListHeight(),
            itemGap: HomeCatalogStripsMetrics.itemGap(),
            onViewAll: _openCategoriesTab,
            itemCount: categories.length,
            itemBuilder: (index) {
              final category = categories[index];
              return _CategoryItem(
                category: category,
                onTap: () => SectionDetailPage.open(
                  category,
                  shopId: category.shopId,
                ),
              );
            },
          ),
        if (brands.isNotEmpty)
          _CatalogStrip(
            title: 'برانداتنا',
            titleTop: categories.isEmpty
                ? HomeCatalogStripsMetrics.titleTop()
                : HomeCatalogStripsMetrics.sectionsToBrandsGap(),
            listHeight: HomeCatalogStripsMetrics.brandListHeight(),
            itemGap: HomeCatalogStripsMetrics.brandItemGap(),
            onViewAll: _openBrandsPage,
            itemCount: brands.length,
            itemBuilder: (index) {
              final brand = brands[index];
              return _BrandItem(
                brand: brand,
                onTap: () => BrandProductsPage.openFromHome(brand),
              );
            },
          ),
      ],
    );
  }
}

class _CatalogStrip extends StatelessWidget {
  const _CatalogStrip({
    required this.title,
    required this.titleTop,
    required this.listHeight,
    required this.itemGap,
    required this.onViewAll,
    required this.itemCount,
    required this.itemBuilder,
  });

  final String title;
  final double titleTop;
  final double listHeight;
  final double itemGap;
  final VoidCallback onViewAll;
  final int itemCount;
  final Widget Function(int index) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            20.w,
            titleTop,
            20.w,
            HomeCatalogStripsMetrics.titleBottom(),
          ),
          child: Row(
            children: [
              Expanded(
                child: MyText(
                  title,
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: onViewAll,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MyText(
                      'عرض الكل',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
                    SizedBox(width: 2.w),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Icon(
                        Icons.chevron_left_rounded,
                        size: 18.sp,
                        color: Colors.black.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: listHeight,
          child: ListView.separated(
            clipBehavior: Clip.none,
            padding: HomeCatalogStripsMetrics.listPadding(),
            scrollDirection: Axis.horizontal,
            itemCount: itemCount,
            separatorBuilder: (_, _) => SizedBox(width: itemGap),
            itemBuilder: (context, index) => itemBuilder(index),
          ),
        ),
      ],
    );
  }
}

class _CategoryItem extends StatelessWidget {
  const _CategoryItem({
    required this.category,
    required this.onTap,
  });

  final CategoryModel category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final size = HomeCatalogStripsMetrics.categoryBoxSize();
    final radius = BorderRadius.circular(
      HomeCatalogStripsMetrics.categoryRadius(),
    );

    return Align(
      alignment: Alignment.topCenter,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: size,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: HomeCatalogStripsMetrics.categoryFill(),
                  borderRadius: radius,
                  boxShadow: HomeCatalogStripsMetrics.containerShadow(),
                ),
                padding: EdgeInsets.all(
                  HomeCatalogStripsMetrics.categoryIconPadding(),
                ),
                child: CategoryIconWidget(
                  category: category,
                  size: HomeCatalogStripsMetrics.categoryIconSize(),
                ),
              ),
              SizedBox(height: HomeCatalogStripsMetrics.categoryLabelGap()),
              SizedBox(
                height: HomeCatalogStripsMetrics.categoryLabelHeight(),
                child: MyText(
                  category.name,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF022B2F),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandItem extends StatelessWidget {
  const _BrandItem({
    required this.brand,
    required this.onTap,
  });

  final BrandModel brand;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(
      HomeCatalogStripsMetrics.brandRadius(),
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: HomeCatalogStripsMetrics.brandWidth(),
        height: HomeCatalogStripsMetrics.brandHeight(),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: radius,
          boxShadow: HomeCatalogStripsMetrics.containerShadow(),
        ),
        alignment: Alignment.center,
        child: brand.hasImage
            ? AppImage(
                source: brand.imageUrl,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorIcon: Icons.storefront_outlined,
              )
            : Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                child: MyText(
                  brand.name,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
      ),
    );
  }
}
