import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controllers/cart_controller.dart';
import '../../controllers/product_detail_controller.dart';
import '../../utils/price_formatter.dart';
import '../../widgets/cart/cart_bottom_sheet.dart';
import '../../core/config/api_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/product.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_spacing.dart';

/// شاشة تفاصيل المنتج — تُفتح من البطاقة في الصفحة الرئيسية.
/// المنتج يُمرَّر عبر Get.arguments (Map أو Product).
class ProductDetailScreen extends GetView<ProductDetailController> {
  const ProductDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          controller.product.name,
          style: TextStyle(
            fontFamily: kFontFamilyCairo,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20.sp),
          onPressed: () => Get.back(),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _ProductImageSection(
              imageUrl: ApiConfig.productImageUrl(controller.product.image),
              emoji: controller.product.emoji,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
              child: _ProductInfoSection(product: controller.product),
            ),
          ),
          SliverToBoxAdapter(child: AppSpacing.verticalMd),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Obx(
                () => _QuantitySection(
                  quantity: controller.quantity.value,
                  onDecrement: controller.decrementQuantity,
                  onIncrement: controller.incrementQuantity,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(child: AppSpacing.verticalLg),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: _DescriptionSection(description: controller.product.description),
            ),
          ),
          SliverToBoxAdapter(child: AppSpacing.verticalLg),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: _ShopRow(shopName: controller.product.shopName ?? 'متجر'),
            ),
          ),
          SliverToBoxAdapter(child: AppSpacing.verticalXl),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
                child: AppButton(
                label: 'إضافة للسلة',
                onPressed: () {
                  final q = controller.quantity.value;
                  Get.find<CartController>().add(controller.product, quantity: q);
                  CartBottomSheet.show();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// محدد الكمية — عنوان + أزرار ناقص / رقم / زائد.
class _QuantitySection extends StatelessWidget {
  const _QuantitySection({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الكمية',
          style: TextStyle(
            fontFamily: kFontFamilyCairo,
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDark,
          ),
        ),
        AppSpacing.verticalSm,
        Row(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: quantity > 1 ? onDecrement : null,
                borderRadius: BorderRadius.circular(12.r),
                child: Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    color: quantity > 1 ? AppColors.primaryLight : AppColors.border.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: AppColors.border),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.remove_rounded,
                    size: 22.sp,
                    color: quantity > 1 ? AppColors.primaryDark : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Text(
                '$quantity',
                style: TextStyle(
                  fontFamily: kFontFamilyCairo,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onIncrement,
                borderRadius: BorderRadius.circular(12.r),
                child: Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: AppColors.primaryDark),
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.add_rounded, size: 22.sp, color: AppColors.primaryLight),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// منطقة صورة المنتج — تدرج مع emoji أو صورة.
class _ProductImageSection extends StatelessWidget {
  const _ProductImageSection({this.imageUrl, this.emoji});

  final String? imageUrl;
  final String? emoji;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280.h,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            AppColors.primaryLight,
            AppColors.primaryBeige.withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24.r),
          bottomRight: Radius.circular(24.r),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24.r),
          bottomRight: Radius.circular(24.r),
        ),
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => _placeholder(),
                errorWidget: (_, __, ___) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Center(
      child: Text(
        emoji ?? '🛒',
        style: TextStyle(fontSize: 80.sp),
      ),
    );
  }
}

/// اسم المنتج، السعر، الوحدة، وشارة التوفر.
class _ProductInfoSection extends StatelessWidget {
  const _ProductInfoSection({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                product.name,
                style: TextStyle(
                  fontFamily: kFontFamilyCairo,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
            _AvailabilityChip(isAvailable: product.isAvailable),
          ],
        ),
        AppSpacing.verticalMd,
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              formatPrice(product.price),
              style: TextStyle(
                fontFamily: kFontFamilyCairo,
                fontSize: 24.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
            if (product.unit != null && product.unit!.isNotEmpty) ...[
              SizedBox(width: 6.w),
              Text(
                '/ ${product.unit}',
                style: TextStyle(
                  fontFamily: kFontFamilyCairo,
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _AvailabilityChip extends StatelessWidget {
  const _AvailabilityChip({required this.isAvailable});

  final bool isAvailable;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: isAvailable
            ? AppColors.primaryLight.withValues(alpha: 0.8)
            : AppColors.error.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isAvailable ? AppColors.primaryMedium.withValues(alpha: 0.5) : AppColors.error.withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        isAvailable ? 'متوفر' : 'غير متوفر',
        style: TextStyle(
          fontFamily: kFontFamilyCairo,
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: isAvailable ? AppColors.primaryDark : AppColors.error,
        ),
      ),
    );
  }
}

/// قسم الوصف بعنوان ونص.
class _DescriptionSection extends StatelessWidget {
  const _DescriptionSection({this.description});

  final String? description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الوصف',
          style: TextStyle(
            fontFamily: kFontFamilyCairo,
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDark,
          ),
        ),
        AppSpacing.verticalSm,
        Text(
          description ?? 'لا يوجد وصف لهذا المنتج.',
          style: TextStyle(
            fontFamily: kFontFamilyCairo,
            fontSize: 15.sp,
            height: 1.5,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// صف المتجر — أيقونة + اسم.
class _ShopRow extends StatelessWidget {
  const _ShopRow({required this.shopName});

  final String shopName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48.w,
            height: 48.h,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: AppColors.border),
            ),
            alignment: Alignment.center,
            child: Text('🛒', style: TextStyle(fontSize: 24.sp)),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              shopName,
              style: TextStyle(
                fontFamily: kFontFamilyCairo,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, size: 14.sp, color: AppColors.primaryMedium),
        ],
      ),
    );
  }
}
