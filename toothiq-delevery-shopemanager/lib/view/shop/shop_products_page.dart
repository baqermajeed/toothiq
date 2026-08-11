import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controller/shop_products_controller.dart';
import '../../utils/app_colors.dart';
import '../../widget/my_text.dart';
import '../../widget/shop/shop_product_card.dart';
import 'product_form_page.dart';
import 'shop_product_details_page.dart';

class ShopProductsPage extends StatelessWidget {
  const ShopProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ShopProductsController>();

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            backgroundColor: AppColors.pageBackground,
            title: MyText('منتجات المتجر', fontSize: 18.sp),
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(56.h),
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
                child: TextField(
                  onChanged: (v) => controller.searchQuery.value = v,
                  textAlign: TextAlign.right,
                  style: TextStyle(fontFamily: 'Expo Arabic', fontSize: 14.sp),
                  decoration: InputDecoration(
                    hintText: 'بحث بالاسم، القسم أو البراند...',
                    hintStyle: TextStyle(
                      fontFamily: 'Expo Arabic',
                      fontSize: 13.sp,
                      color: AppColors.textSecondary,
                    ),
                    prefixIcon: Icon(Icons.search, color: AppColors.textSecondary, size: 22.sp),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.r),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.r),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Obx(() {
              final available = controller.availableCount;
              final total = controller.products.length;
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Row(
                  children: [
                    _MiniStat(label: 'الكل', value: '$total', color: AppColors.primary),
                    SizedBox(width: 10.w),
                    _MiniStat(label: 'متاح', value: '$available', color: AppColors.success),
                    SizedBox(width: 10.w),
                    _MiniStat(
                      label: 'مخفي',
                      value: '${total - available}',
                      color: AppColors.warning,
                    ),
                  ],
                ),
              );
            }),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
            sliver: Obx(() {
              final list = controller.filteredProducts;
              if (list.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64.sp,
                          color: AppColors.textLight,
                        ),
                        SizedBox(height: 12.h),
                        MyText(
                          controller.searchQuery.value.isEmpty
                              ? 'لا توجد منتجات — أضف أول منتج'
                              : 'لا توجد نتائج للبحث',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14.h,
                  crossAxisSpacing: 14.w,
                  childAspectRatio: 0.54,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product = list[index];
                    return ShopProductCard(
                      product: product,
                      onTap: () => ShopProductDetailsPage.open(product),
                      onImageTap: () => ShopProductDetailsPage.open(product),
                      onToggle: () => controller.toggleAvailability(product.id),
                      onEdit: () {
                        final latest = controller.findProduct(product.id) ?? product;
                        Get.to(() => ProductFormPage(product: latest));
                      },
                      onDelete: () => confirmDeleteProduct(
                        product,
                        () => controller.removeProduct(product.id),
                      ),
                    );
                  },
                  childCount: list.length,
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.to(() => const ProductFormPage()),
        backgroundColor: AppColors.primary,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: MyText('إضافة منتج', fontSize: 13.sp, color: Colors.white),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            MyText(value, fontSize: 18.sp, color: color),
            SizedBox(height: 2.h),
            MyText(
              label,
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.8),
            ),
          ],
        ),
      ),
    );
  }
}
