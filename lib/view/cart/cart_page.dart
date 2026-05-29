import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../bindings/cart_binding.dart';
import '../../controller/cart_controller.dart';
import '../../utils/app_colors.dart';
import '../../widget/cart/cart_app_bar.dart';
import '../../widget/cart/cart_bottom_bar.dart';
import '../../widget/cart/cart_confirm_dialog.dart';
import '../../widget/cart/cart_item_card_widget.dart';
import '../../widget/my_text.dart';
import '../../widget/orders/order_info_card.dart';

class CartPage extends GetView<CartController> {
  const CartPage({super.key});

  static void open() {
    CartBinding().dependencies();
    Get.to(() => const CartPage());
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Obx(() {
        final itemCount = controller.items.length;
        final isEmpty = itemCount == 0;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: CartAppBar(
            showClearButton: !isEmpty,
            onClearTap: () => _confirmClearCart(controller),
          ),
          body: Column(
            children: [
              Expanded(
                child: isEmpty
                    ? const _CartEmptyState()
                    : _CartFilledBody(controller: controller),
              ),
              if (!isEmpty) CartBottomBar(controller: controller),
            ],
          ),
        );
      }),
    );
  }
}

Future<void> _confirmClearCart(CartController cart) async {
  final confirmed = await CartConfirmDialog.showClearCart();
  if (confirmed == true) cart.clearCart();
}

class _CartEmptyState extends StatelessWidget {
  const _CartEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/cart/cart_empty.png',
              width: 280.w,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.shopping_cart_outlined,
                size: 120.sp,
                color: AppColors.textLight,
              ),
            ),
            SizedBox(height: 24.h),
            MyText(
              'السلة فارغة ! أضف أول منتج الآن',
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.productTitle,
              textAlign: TextAlign.center,
              height: 1.5,
            ),
          ],
        ),
      ),
    );
  }
}

class _CartFilledBody extends StatelessWidget {
  final CartController controller;

  const _CartFilledBody({required this.controller});

  Future<void> _confirmRemoveItem(String productId) async {
    final confirmed = await CartConfirmDialog.showRemoveItem();
    if (confirmed == true) controller.removeItem(productId);
  }

  @override
  Widget build(BuildContext context) {
    final items = controller.items;

    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
      children: [
        MyText(
          'المنتجات ( ${controller.itemCount} )',
          fontSize: 16.sp,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
          textAlign: TextAlign.right,
        ),
        SizedBox(height: 12.h),
        ...items.map(
          (item) => Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: CartItemCardWidget(
              item: item,
              onRemove: () => _confirmRemoveItem(item.product.id),
              onIncrement: () => controller.incrementQuantity(item.product.id),
              onDecrement: () => controller.decrementQuantity(item.product.id),
            ),
          ),
        ),
        SizedBox(height: 8.h),
        MyText(
          'تفاصيل السعر',
          fontSize: 16.sp,
          fontWeight: FontWeight.w800,
          color: AppColors.productTitle,
          textAlign: TextAlign.right,
        ),
        SizedBox(height: 10.h),
        OrderInfoCard(
          fields: [
            OrderInfoField(
              label: 'سعر الطلب :',
              value: controller.formattedOrderPrice,
            ),
            const OrderInfoField(
              label: 'سعر التوصيل :',
              value: 'مجاني',
            ),
            OrderInfoField(
              label: 'السعر الكلي :',
              value: controller.formattedTotalPrice,
              highlightValue: true,
              valueIsGreen: true,
            ),
          ],
        ),
      ],
    );
  }
}
