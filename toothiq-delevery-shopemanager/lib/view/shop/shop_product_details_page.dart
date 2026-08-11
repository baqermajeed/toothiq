import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controller/shop_products_controller.dart';
import '../../model/shop_product.dart';
import '../../utils/app_colors.dart';
import '../../widget/my_text.dart';
import '../../widget/shop/app_image.dart';
import '../../widget/shop/shop_product_card.dart';
import 'product_form_page.dart';

class ShopProductDetailsPage extends StatefulWidget {
  const ShopProductDetailsPage({super.key, required this.productId});

  final String productId;

  static void open(ShopProduct product) {
    Get.to(() => ShopProductDetailsPage(productId: product.id));
  }

  @override
  State<ShopProductDetailsPage> createState() => _ShopProductDetailsPageState();
}

class _ShopProductDetailsPageState extends State<ShopProductDetailsPage> {
  final _pageController = PageController();
  int _imageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _openEdit(ShopProduct product) async {
    await Get.to(() => ProductFormPage(product: product));
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ShopProductsController>();

    return Obx(() {
      final product = controller.findProduct(widget.productId);
      if (product == null) {
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new),
              onPressed: Get.back,
            ),
            title: MyText('تفاصيل المنتج', fontSize: 18.sp),
          ),
          body: Center(
            child: MyText(
              'المنتج غير موجود',
              fontSize: 14.sp,
              color: AppColors.textSecondary,
            ),
          ),
        );
      }

      final images = product.allImages;

      return Scaffold(
        backgroundColor: AppColors.pageBackground,
        appBar: AppBar(
          title: MyText('تفاصيل المنتج', fontSize: 18.sp),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: Get.back,
          ),
          actions: [
            IconButton(
              tooltip: 'تعديل',
              onPressed: () => _openEdit(product),
              icon: Icon(Icons.edit_outlined, size: 22.sp),
            ),
          ],
        ),
        body: ListView(
          padding: EdgeInsets.only(bottom: 24.h),
          children: [
            _ImageGallery(
              images: images,
              pageController: _pageController,
              imageIndex: _imageIndex,
              isAvailable: product.isAvailable,
              onPageChanged: (index) => setState(() => _imageIndex = index),
            ),
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyText(
                    product.name,
                    fontSize: 20.sp,
                    maxLines: 3,
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      MyText(
                        product.formattedPrice,
                        fontSize: 22.sp,
                        color: AppColors.primary,
                      ),
                      const Spacer(),
                      _InfoChip(
                        icon: Icons.inventory_2_outlined,
                        label: 'الكمية: ${product.stock}',
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  _DetailsCard(
                    children: [
                      if (product.categoryName != null)
                        _DetailRow(
                          icon: Icons.category_outlined,
                          label: 'القسم',
                          value: product.categoryName!,
                        ),
                      if (product.brandName != null)
                        _DetailRow(
                          icon: Icons.sell_outlined,
                          label: 'البراند',
                          value: product.brandName!,
                        ),
                      if (product.origin != null && product.origin!.isNotEmpty)
                        _DetailRow(
                          icon: Icons.public_outlined,
                          label: 'المنشأ',
                          value: product.origin!,
                        ),
                      if (product.expiryDate != null &&
                          product.expiryDate!.isNotEmpty)
                        _DetailRow(
                          icon: Icons.event_outlined,
                          label: 'تاريخ الانتهاء',
                          value: product.expiryDate!,
                        ),
                      _DetailRow(
                        icon: product.isAvailable
                            ? Icons.check_circle_outline
                            : Icons.hide_source_outlined,
                        label: 'الحالة',
                        value: product.isAvailable ? 'متاح للبيع' : 'مخفي',
                        valueColor: product.isAvailable
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  _DetailsCard(
                    title: 'وصف المنتج',
                    children: [
                      MyText(
                        product.description.isEmpty
                            ? 'لا يوجد وصف لهذا المنتج.'
                            : product.description,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              controller.toggleAvailability(product.id),
                          icon: Icon(
                            product.isAvailable
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 18.sp,
                          ),
                          label: Text(
                            product.isAvailable ? 'إخفاء المنتج' : 'إظهار المنتج',
                            style: TextStyle(
                              fontFamily: 'Expo Arabic',
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: Size(double.infinity, 48.h),
                            side: const BorderSide(color: AppColors.cardBorder),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _openEdit(product),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: Text(
                            'تعديل',
                            style: TextStyle(
                              fontFamily: 'Expo Arabic',
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            minimumSize: Size(double.infinity, 48.h),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () => confirmDeleteProduct(
                        product,
                        () {
                          controller.removeProduct(product.id);
                          Get.back();
                        },
                      ),
                      icon: Icon(Icons.delete_outline, color: AppColors.error, size: 20.sp),
                      label: MyText(
                        'حذف المنتج',
                        fontSize: 13.sp,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _ImageGallery extends StatelessWidget {
  const _ImageGallery({
    required this.images,
    required this.pageController,
    required this.imageIndex,
    required this.isAvailable,
    required this.onPageChanged,
  });

  final List<String> images;
  final PageController pageController;
  final int imageIndex;
  final bool isAvailable;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 1.1,
          child: images.isEmpty
              ? AppImage(
                  width: double.infinity,
                  height: double.infinity,
                  icon: Icons.medical_services_outlined,
                )
              : PageView.builder(
                  controller: pageController,
                  itemCount: images.length,
                  onPageChanged: onPageChanged,
                  itemBuilder: (context, index) {
                    return AppImage(
                      path: images[index],
                      width: double.infinity,
                      height: double.infinity,
                      icon: Icons.medical_services_outlined,
                    );
                  },
                ),
        ),
        Positioned(
          top: 14.h,
          right: 14.w,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: isAvailable
                  ? AppColors.success.withValues(alpha: 0.92)
                  : AppColors.error.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: MyText(
              isAvailable ? 'متاح' : 'مخفي',
              fontSize: 11.sp,
              color: Colors.white,
            ),
          ),
        ),
        if (images.length > 1)
          Positioned(
            bottom: 12.h,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(images.length, (index) {
                final active = index == imageIndex;
                return Container(
                  width: active ? 18.w : 7.w,
                  height: 7.h,
                  margin: EdgeInsets.symmetric(horizontal: 3.w),
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.primary
                        : Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({
    this.title,
    required this.children,
  });

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            MyText(title!, fontSize: 15.sp),
            SizedBox(height: 12.h),
          ],
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        children: [
          Icon(icon, size: 18.sp, color: AppColors.primary),
          SizedBox(width: 8.w),
          MyText(
            '$label:',
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
          SizedBox(width: 6.w),
          Expanded(
            child: MyText(
              value,
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.textPrimary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: AppColors.primary),
          SizedBox(width: 4.w),
          MyText(label, fontSize: 11.sp, color: AppColors.primary),
        ],
      ),
    );
  }
}
