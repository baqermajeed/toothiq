import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controller/shop_catalog_controller.dart';
import '../../controller/shop_products_controller.dart';
import '../../model/shop_brand.dart';
import '../../model/shop_category.dart';
import '../../model/shop_product.dart';
import '../../utils/app_colors.dart';
import '../../widget/my_text.dart';
import '../../widget/shop/app_image.dart';
import '../../widget/shop/shop_product_card.dart';
import 'product_form_page.dart';
import 'shop_product_details_page.dart';

class ShopFilteredProductsPage extends StatefulWidget {
  const ShopFilteredProductsPage({
    super.key,
    required this.title,
    this.category,
    this.brand,
  });

  final String title;
  final ShopCategory? category;
  final ShopBrand? brand;

  static void open({
    required String title,
    ShopCategory? category,
    ShopBrand? brand,
  }) {
    Get.to(
      () => ShopFilteredProductsPage(
        title: title,
        category: category,
        brand: brand,
      ),
    );
  }

  @override
  State<ShopFilteredProductsPage> createState() =>
      _ShopFilteredProductsPageState();
}

class _ShopFilteredProductsPageState extends State<ShopFilteredProductsPage> {
  String? _brandId;

  @override
  void initState() {
    super.initState();
    _brandId = widget.brand?.id;
  }

  @override
  Widget build(BuildContext context) {
    final productsCtrl = Get.find<ShopProductsController>();
    final catalog = Get.find<ShopCatalogController>();

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: MyText(widget.title, fontSize: 18.sp),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: Get.back,
        ),
      ),
      body: Obx(() {
        final _ = productsCtrl.products.length;
        var list = widget.category != null
            ? productsCtrl.productsInCategory(widget.category!)
            : productsCtrl.products.toList();
        if (_brandId != null) {
          list = list.where((p) => p.brandId == _brandId).toList();
        }

        final brands = widget.category != null
            ? productsCtrl.brandsInCategory(widget.category!, catalog.brands)
            : const <ShopBrand>[];

        return Column(
          children: [
            if (brands.isNotEmpty)
              _BrandFilterBar(
                brands: brands,
                selectedId: _brandId,
                onSelected: (id) => setState(() {
                  _brandId = _brandId == id ? null : id;
                }),
              ),
            Expanded(
              child: list.isEmpty
                  ? _EmptyFiltered(title: widget.title)
                  : GridView.builder(
                      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 14.h,
                        crossAxisSpacing: 14.w,
                        childAspectRatio: 0.62,
                      ),
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final product = list[index];
                        return _productCard(productsCtrl, product);
                      },
                    ),
            ),
          ],
        );
      }),
    );
  }

  Widget _productCard(ShopProductsController controller, ShopProduct product) {
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
  }
}

class _BrandFilterBar extends StatelessWidget {
  const _BrandFilterBar({
    required this.brands,
    required this.selectedId,
    required this.onSelected,
  });

  final List<ShopBrand> brands;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
            child: MyText('البراندات', fontSize: 13.sp),
          ),
          SizedBox(
            height: 52.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              itemCount: brands.length,
              separatorBuilder: (_, __) => SizedBox(width: 8.w),
              itemBuilder: (context, index) {
                final brand = brands[index];
                final selected = selectedId == brand.id;
                return InkWell(
                  onTap: () => onSelected(brand.id),
                  borderRadius: BorderRadius.circular(20.r),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primaryLight
                          : AppColors.pageBackground,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: selected ? AppColors.primary : AppColors.cardBorder,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppImage(
                          path: brand.logoPath,
                          width: 22.w,
                          height: 22.w,
                          borderRadius: BorderRadius.circular(6.r),
                          icon: Icons.verified_outlined,
                        ),
                        SizedBox(width: 6.w),
                        MyText(
                          brand.nameAr,
                          fontSize: 12.sp,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(height: 1, color: AppColors.cardBorder),
        ],
      ),
    );
  }
}

class _EmptyFiltered extends StatelessWidget {
  const _EmptyFiltered({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72.w,
              height: 72.w,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 34.sp,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 16.h),
            MyText(
              'لا توجد منتجات في «$title»',
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
