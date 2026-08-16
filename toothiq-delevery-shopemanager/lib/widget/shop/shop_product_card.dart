import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../model/shop_product.dart';
import '../../utils/app_colors.dart';
import '../my_text.dart';
import 'app_image.dart';

class ShopProductCard extends StatelessWidget {
  const ShopProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onImageTap,
    this.onToggle,
    this.onEdit,
    this.onDelete,
  });

  final ShopProduct product;
  final VoidCallback? onTap;
  final VoidCallback? onImageTap;
  final VoidCallback? onToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final outOfStock = product.stock <= 0;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18.r),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ImageHeader(
                product: product,
                onTap: onImageTap ?? onTap,
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(10.w, 10.h, 10.w, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MyText(
                        product.name,
                        fontSize: 13.sp,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        height: 1.25,
                      ),
                      const Spacer(),
                      if (product.isOnOffer) ...[
                        Text(
                          product.formattedOriginalPrice,
                          style: TextStyle(
                            fontFamily: 'Expo Arabic',
                            fontSize: 11.sp,
                            color: AppColors.textSecondary,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        SizedBox(height: 2.h),
                      ],
                      MyText(
                        product.formattedPrice,
                        fontSize: 14.sp,
                        color: AppColors.primary,
                      ),
                      if (product.isOnOffer) ...[
                        SizedBox(height: 4.h),
                        MyText(
                          product.offerBadgeLabel,
                          fontSize: 11.sp,
                          color: AppColors.error,
                        ),
                      ],
                      SizedBox(height: 6.h),
                      Wrap(
                        spacing: 6.w,
                        runSpacing: 4.h,
                        children: [
                          _MetaChip(
                            icon: Icons.inventory_2_outlined,
                            label: outOfStock ? 'نفد' : '${product.stock}',
                            color: outOfStock
                                ? AppColors.error
                                : AppColors.textSecondary,
                          ),
                          if (product.categoryName != null)
                            _MetaChip(
                              icon: Icons.category_outlined,
                              label: product.categoryName!,
                              color: AppColors.primary,
                            ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                    ],
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.cardBorder)),
                ),
                child: Row(
                  children: [
                    _IconAction(
                      icon: product.isAvailable
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      tooltip: product.isAvailable ? 'إخفاء' : 'إظهار',
                      onTap: onToggle,
                    ),
                    _IconAction(
                      icon: Icons.edit_outlined,
                      tooltip: 'تعديل',
                      onTap: onEdit,
                    ),
                    _IconAction(
                      icon: Icons.delete_outline,
                      tooltip: 'حذف',
                      color: AppColors.error,
                      onTap: onDelete,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageHeader extends StatelessWidget {
  const _ImageHeader({required this.product, this.onTap});

  final ShopProduct product;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: 118.h,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Opacity(
              opacity: product.isAvailable ? 1 : 0.55,
              child: AppImage(
                path: product.primaryImage,
                width: double.infinity,
                height: 118.h,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.vertical(top: Radius.circular(17.r)),
                icon: Icons.medical_services_outlined,
              ),
            ),
            Positioned(
              top: 8.h,
              right: 8.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: product.isAvailable
                      ? AppColors.success.withValues(alpha: 0.92)
                      : AppColors.warning.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: MyText(
                  product.isAvailable ? 'متاح' : 'مخفي',
                  fontSize: 10.sp,
                  color: Colors.white,
                ),
              ),
            ),
            if (product.isOnOffer)
              Positioned(
                top: 8.h,
                left: 8.w,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: MyText(
                    product.offerBadgeLabel,
                    fontSize: 10.sp,
                    color: Colors.white,
                  ),
                ),
              ),
            if (product.brandName != null)
              Positioned(
                bottom: 8.h,
                left: 8.w,
                child: Container(
                  constraints: BoxConstraints(maxWidth: 110.w),
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: MyText(
                    product.brandName!,
                    fontSize: 10.sp,
                    color: Colors.white,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11.sp, color: color),
          SizedBox(width: 3.w),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 72.w),
            child: MyText(
              label,
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: color,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.tooltip,
    this.color,
    this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10.r),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: Icon(
              icon,
              size: 20.sp,
              color: color ?? AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

void confirmDeleteProduct(ShopProduct product, VoidCallback onConfirm) {
  Get.dialog(
    AlertDialog(
      title: const Text('حذف المنتج', style: TextStyle(fontFamily: 'Expo Arabic')),
      content: Text(
        'هل تريد حذف "${product.name}"؟',
        style: const TextStyle(fontFamily: 'Expo Arabic'),
      ),
      actions: [
        TextButton(
          onPressed: Get.back,
          child: const Text('إلغاء', style: TextStyle(fontFamily: 'Expo Arabic')),
        ),
        TextButton(
          onPressed: () {
            Get.back();
            onConfirm();
          },
          child: const Text(
            'حذف',
            style: TextStyle(fontFamily: 'Expo Arabic', color: AppColors.error),
          ),
        ),
      ],
    ),
  );
}
