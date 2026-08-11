import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controllers/cart_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/cart/cart_item_tile.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_spacing.dart';
import '../../widgets/order_notes/order_notes_sheet.dart';

/// شاشة السلة — قائمة العناصر، محدد كمية، سعر السطر، والمجموع الكلي.
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Get.find<CartController>();
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20.sp),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'السلة',
          style: TextStyle(
            fontFamily: kFontFamilyCairo,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Obx(() {
        if (cart.items.isEmpty) {
          return _EmptyCartState();
        }
        return Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                physics: const BouncingScrollPhysics(),
                itemCount: cart.items.length,
                separatorBuilder: (_, __) => SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) {
                  final item = cart.items[index];
                  return CartItemTile(
                    item: item,
                    onQuantityChanged: (qty) => cart.updateQuantity(index, qty),
                    onRemove: () => cart.removeAt(index),
                    formatPrice: formatCartPrice,
                  );
                },
              ),
            ),
            CartTotalBar(total: cart.totalPrice, formatPrice: formatCartPrice),
            Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg + 12.h),
              child: SafeArea(
                top: false,
                child: AppButton(
                  label: 'إتمام الطلب',
                  // minHeight: 52.h,
                  onPressed: () => showOrderNotesSheet(),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _EmptyCartState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 72.sp,
            color: AppColors.primaryMedium.withValues(alpha: 0.5),
          ),
          AppSpacing.verticalLg,
          Text(
            'السلة فارغة',
            style: TextStyle(
              fontFamily: kFontFamilyCairo,
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          AppSpacing.verticalSm,
          Text(
            'أضف منتجات من المتجر لتبدأ',
            style: TextStyle(
              fontFamily: kFontFamilyCairo,
              fontSize: 14.sp,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

