import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../bindings/cart_binding.dart';
import '../../bindings/checkout_binding.dart';
import '../../controller/cart_controller.dart';
import '../../controller/checkout_controller.dart';
import '../../service_layer/services/platform_settings_service.dart';
import '../../utils/app_colors.dart';
import '../../widget/basket/basket_app_bar.dart';
import '../../widget/basket/basket_bottom_bar.dart';
import '../../widget/basket/basket_item_card.dart';
import '../../widget/cart/cart_confirm_dialog.dart';
import '../../widget/cart/cart_icon.dart';
import '../../widget/common/async_state_widgets.dart';
import '../../widget/my_text.dart';
import '../../widget/orders/order_info_card.dart';

/// واجهة السلة — مطابقة لتصميم Figma
class BasketPage extends GetView<CartController> {
  const BasketPage({super.key});

  static void open() {
    CartBinding().dependencies();
    if (Get.isRegistered<PlatformSettingsService>()) {
      unawaited(Get.find<PlatformSettingsService>().refresh());
    }
    Get.to(() => const BasketPage());
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Obx(() {
        final isEmpty = controller.items.isEmpty;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: BasketAppBar(
            showClearButton: !isEmpty,
            onClearTap: () => _confirmClearCart(controller),
          ),
          body: Column(
            children: [
              Expanded(
                child: isEmpty
                    ? AppEmptyState(
                        title: 'السلة فارغة ! أضف أول منتج الآن',
                        iconWidget: CartIcon(
                          size: 62.sp,
                          color: AppColors.textLight,
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: () async {
                          controller.items.refresh();
                        },
                        child: _BasketFilledBody(controller: controller),
                      ),
              ),
              if (!isEmpty)
                BasketBottomBar(
                  label: 'أكمال الشراء',
                  onTap: _onCompletePurchase,
                ),
            ],
          ),
        );
      }),
    );
  }

  void _onCompletePurchase() {
    CheckoutBinding().dependencies();
    Get.find<CheckoutController>().startCheckout();
  }
}

Future<void> _confirmClearCart(CartController cart) async {
  final confirmed = await CartConfirmDialog.showClearCart();
  if (confirmed == true) cart.clearCart();
}

class _BasketFilledBody extends StatelessWidget {
  final CartController controller;

  const _BasketFilledBody({required this.controller});

  @override
  Widget build(BuildContext context) {
    final items = controller.items;
    final platform = Get.find<PlatformSettingsService>();

    return Obx(
      () {
        // يعيد بناء تفاصيل السعر عند تحديث رسوم التوصيل من الـ API.
        platform.contact.value;

        return ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
          children: [
            MyText(
              'المنتجات ( ${controller.itemCount} )',
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.productTitle,
              textAlign: TextAlign.right,
            ),
            SizedBox(height: 12.h),
            ...items.map(
              (item) => Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: BasketItemCard(
                  item: item,
                  onIncrement: () =>
                      controller.incrementQuantity(item.product.id),
                  onDecrement: () =>
                      controller.decrementQuantity(item.product.id),
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
                OrderInfoField(
                  label: 'سعر التوصيل :',
                  value: controller.formattedDeliveryFee,
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
      },
    );
  }
}
