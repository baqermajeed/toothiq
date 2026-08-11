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
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18.r),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18.r),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  GestureDetector(
                    onTap: onImageTap ?? onTap,
                    child: SizedBox(
                      width: double.infinity,
                      height: 108.h,
                      child: AppImage(
                        path: product.primaryImage,
                        width: double.infinity,
                        height: 108.h,
                        fit: BoxFit.cover,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(18.r)),
                        icon: Icons.medical_services_outlined,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10.h,
                    right: 10.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: product.isAvailable
                            ? AppColors.success.withValues(alpha: 0.92)
                            : AppColors.error.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: MyText(
                        product.isAvailable ? 'متاح' : 'مخفي',
                        fontSize: 10.sp,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (product.brandName != null)
                    Positioned(
                      bottom: 10.h,
                      left: 10.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: MyText(
                          product.brandName!,
                          fontSize: 10.sp,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(10.w, 10.h, 10.w, 10.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MyText(
                      product.name,
                      fontSize: 13.sp,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (product.description.isNotEmpty) ...[
                      SizedBox(height: 3.h),
                      MyText(
                        product.description,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    SizedBox(height: 6.h),
                    Row(
                      children: [
                        Expanded(
                          child: MyText(
                            product.formattedPrice,
                            fontSize: 13.sp,
                            color: AppColors.primary,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 13.sp,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(width: 3.w),
                        MyText(
                          '${product.stock}',
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                    if (product.categoryName != null) ...[
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(
                            Icons.category_outlined,
                            size: 12.sp,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 3.w),
                          Expanded(
                            child: MyText(
                              product.categoryName!,
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionChip(
                            icon: product.isAvailable
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            label: product.isAvailable ? 'إخفاء' : 'إظهار',
                            onTap: onToggle,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: _ActionChip(
                            icon: Icons.edit_outlined,
                            label: 'تعديل',
                            onTap: onEdit,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        GestureDetector(
                          onTap: onDelete,
                          child: Padding(
                            padding: EdgeInsets.all(4.w),
                            child: Icon(
                              Icons.delete_outline,
                              color: AppColors.error,
                              size: 18.sp,
                            ),
                          ),
                        ),
                      ],
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

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: AppColors.pageBackground,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13.sp, color: AppColors.textSecondary),
            SizedBox(width: 3.w),
            Flexible(
              child: MyText(
                label,
                fontSize: 9.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
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
          child: const Text('حذف', style: TextStyle(fontFamily: 'Expo Arabic', color: AppColors.error)),
        ),
      ],
    ),
  );
}
