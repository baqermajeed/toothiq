import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controller/checkout_controller.dart';
import '../../utils/app_colors.dart';
import '../../widget/basket/basket_app_bar.dart';
import '../../widget/basket/basket_bottom_bar.dart';
import '../../widget/basket/basket_item_card.dart';
import '../../widget/basket/checkout_step_indicator.dart';
import '../../widget/my_text.dart';
import '../../widget/orders/order_info_card.dart';

/// مرحلة ٢ — تأكيد الطلب قبل الإرسال
class CheckoutConfirmPage extends GetView<CheckoutController> {
  const CheckoutConfirmPage({super.key});

  static void open() {
    Get.to(() => const CheckoutConfirmPage());
  }

  @override
  Widget build(BuildContext context) {
    final cart = controller.cart;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: const BasketAppBar(title: 'تأكيد الطلب'),
        body: Column(
          children: [
            const CheckoutStepIndicator(currentIndex: 1),
            Expanded(
              child: Obx(
                () => ListView(
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                  children: [
                    MyText(
                      'بيانات التوصيل',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.productTitle,
                      textAlign: TextAlign.right,
                    ),
                    SizedBox(height: 10.h),
                    OrderInfoCard(
                      fields: [
                        OrderInfoField(
                          label: 'أسم الزبون :',
                          value: controller.customerNameCtrl.text.trim(),
                        ),
                        OrderInfoField(
                          label: 'رقم الهاتف :',
                          value: controller.phoneCtrl.text.trim(),
                        ),
                        if (controller.altPhoneCtrl.text.trim().isNotEmpty)
                          OrderInfoField(
                            label: 'رقم هاتف آخر :',
                            value: controller.altPhoneCtrl.text.trim(),
                          ),
                        OrderInfoField(
                          label: 'عنوان التوصيل :',
                          value: controller.selectedAddress.value ?? '',
                        ),
                        OrderInfoField(
                          label: 'وقت التوصيل :',
                          value: controller.deliveryTimeLabel,
                        ),
                        OrderInfoField(
                          label: 'طريقة الدفع :',
                          value: controller.paymentMethodLabel,
                        ),
                      ],
                    ),
                    SizedBox(height: 18.h),
                    MyText(
                      'المنتجات ( ${cart.itemCount} )',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.productTitle,
                      textAlign: TextAlign.right,
                    ),
                    SizedBox(height: 12.h),
                    ...cart.items.map(
                      (item) => Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: BasketItemCard(
                          item: item,
                          onIncrement: () =>
                              cart.incrementQuantity(item.product.id),
                          onDecrement: () =>
                              cart.decrementQuantity(item.product.id),
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
                          value: cart.formattedOrderPrice,
                        ),
                        const OrderInfoField(
                          label: 'سعر التوصيل :',
                          value: 'مجاني',
                        ),
                        OrderInfoField(
                          label: 'السعر الكلي :',
                          value: cart.formattedTotalPrice,
                          highlightValue: true,
                          valueIsGreen: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Obx(
              () => BasketBottomBar(
                label: 'إرسال الطلب',
                isLoading: controller.isSubmitting.value,
                onTap: controller.submitOrder,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
