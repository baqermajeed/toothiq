import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controller/checkout_controller.dart';
import '../../service_layer/services/platform_settings_service.dart';
import '../../model/order_line_item_model.dart';
import '../../utils/app_colors.dart';
import '../../widget/basket/checkout_confirm_bottom_bar.dart';
import '../../widget/cart/cart_icon.dart';
import '../../widget/common/async_state_widgets.dart';
import '../../widget/my_text.dart';
import '../../widget/orders/order_detail_app_bar.dart';
import '../../widget/orders/order_info_card.dart';
import '../../widget/orders/order_product_line_widget.dart';

/// مرحلة ٢ — تأكيد الطلب (مطابق لتصميم تفاصيل الطلب)
class CheckoutConfirmPage extends GetView<CheckoutController> {
  const CheckoutConfirmPage({super.key});

  static void open() {
    Get.to(() => const CheckoutConfirmPage());
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: const OrderDetailAppBar(title: 'تأكيد الطلب'),
        bottomNavigationBar: Obx(() {
          if (controller.cart.isEmpty) return const SizedBox.shrink();
          return CheckoutConfirmBottomBar(
            isLoading: controller.isSubmitting.value,
            onSubmit: controller.submitOrder,
          );
        }),
        body: Obx(() {
          final cart = controller.cart;
          if (Get.isRegistered<PlatformSettingsService>()) {
            Get.find<PlatformSettingsService>().contact.value;
          }

          if (cart.isEmpty) {
            return AppEmptyState(
              title: 'السلة فارغة',
              subtitle: 'لا يمكن تأكيد الطلب بدون منتجات',
              iconWidget: CartIcon(
                size: 62.sp,
                color: AppColors.textLight,
              ),
            );
          }

          final now = DateTime.now();
          final orderDate = '${now.year} - ${now.month} - ${now.day}';
          final storeName = cart.items.isNotEmpty
              ? cart.items.first.product.storeName
              : 'أسم المتجر';
          final altPhone = controller.altPhoneCtrl.text.trim();
          final lineItems = cart.items
              .map(
                (item) => OrderLineItemModel(
                  id: item.product.id,
                  name: item.product.name,
                  quantity: item.quantity,
                  unitPrice: item.product.price,
                  imageAsset: item.product.imageAsset,
                ),
              )
              .toList();

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: controller.refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (controller.submitError.value != null) ...[
                    AppErrorState(
                      message: controller.submitError.value!,
                      onRetry: controller.submitOrder,
                      compact: true,
                    ),
                    SizedBox(height: 10.h),
                  ],
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
                      OrderInfoField(
                        label: 'رقم هاتف آخر :',
                        value: altPhone.isEmpty ? 'لا يوجد' : altPhone,
                      ),
                      OrderInfoField(
                        label: 'عنوان التوصيل :',
                        value: controller.selectedAddress.value ?? '',
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),
                  OrderInfoCard(
                    fields: [
                      OrderInfoField(label: 'تاريخ الطلب :', value: orderDate),
                      OrderInfoField(label: 'أسم المتجر :', value: storeName),
                      const OrderInfoField(
                        label: 'عنوان المتجر :',
                        value: 'بابل - شارع الجمعية',
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  MyText(
                    'المنتجات المطلوبة ( ${lineItems.length} )',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.productTitle,
                    textAlign: TextAlign.right,
                  ),
                  SizedBox(height: 12.h),
                  if (lineItems.isEmpty)
                    const AppEmptyState(
                      title: 'لا توجد منتجات في الطلب',
                      icon: Icons.shopping_bag_outlined,
                    )
                  else
                    ...lineItems.map(
                      (item) => Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: OrderProductLineWidget(item: item),
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
                  SizedBox(height: 12.h),
                  OrderInfoCard(
                    fields: [
                      OrderInfoField(
                        label: 'طريقة الدفع :',
                        value: controller.paymentMethodLabel,
                      ),
                      OrderInfoField(
                        label: 'سعر الطلب :',
                        value: cart.formattedOrderPrice,
                        valueIsGreen: true,
                      ),
                      OrderInfoField(
                        label: 'سعر التوصيل :',
                        value: cart.formattedDeliveryFee,
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
          );
        }),
      ),
    );
  }
}
