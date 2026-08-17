import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../bindings/checkout_binding.dart';
import '../../controller/checkout_controller.dart';
import '../../utils/app_colors.dart';
import '../../widget/basket/basket_app_bar.dart';
import '../../widget/basket/basket_bottom_bar.dart';
import '../../widget/basket/order_form_field.dart';
import '../../widget/basket/order_section_title.dart';
import '../../widget/basket/order_picker_field.dart';
import '../../widget/basket/payment_method_tile.dart';
import '../../widget/cart/cart_icon.dart';
import '../../widget/common/async_state_widgets.dart';
import '../../widget/common/skeleton.dart';
import '../settings/saved_addresses_page.dart';

/// طلب منتج — مطابق لتصميم Figma
class NewOrderPage extends GetView<CheckoutController> {
  const NewOrderPage({super.key});

  static void open() {
    CheckoutBinding().dependencies();
    Get.to(() => const NewOrderPage());
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: const BasketAppBar(title: 'طلب منتج'),
        body: Obx(() {
          if (controller.isInitializing.value) {
            return const CheckoutFormSkeleton();
          }

          if (controller.loadError.value != null) {
            return AppErrorState(
              message: controller.loadError.value!,
              onRetry: () => controller.initializeCheckout(),
            );
          }

          if (controller.cart.isEmpty) {
            return AppEmptyState(
              title: 'السلة فارغة',
              subtitle: 'أضف منتجات للسلة قبل إتمام الشراء',
              iconWidget: CartIcon(
                size: 62.sp,
                color: AppColors.textLight,
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: controller.refresh,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 16.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const OrderSectionTitle(title: 'أكتب معلوماتك'),
                        Obx(
                          () => OrderFormField(
                            controller: controller.customerNameCtrl,
                            hint: 'أسم الطبيب',
                            icon: Icons.person_outline,
                            errorText: controller.customerNameError.value,
                            onChanged: (_) {
                              if (controller.customerNameError.value != null) {
                                controller.customerNameError.value = null;
                              }
                            },
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Obx(
                          () => OrderFormField(
                            controller: controller.phoneCtrl,
                            hint: '0770 000 000',
                            icon: Icons.phone_android_outlined,
                            keyboardType: TextInputType.phone,
                            errorText: controller.phoneError.value,
                            onChanged: (_) {
                              if (controller.phoneError.value != null) {
                                controller.phoneError.value = null;
                              }
                            },
                          ),
                        ),
                        SizedBox(height: 12.h),
                        OrderFormField(
                          controller: controller.altPhoneCtrl,
                          hint: '( رقم ثاني ( أختياري',
                          icon: Icons.phone_android_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        SizedBox(height: 22.h),
                        const OrderSectionTitle(title: 'العنوان'),
                        Obx(
                          () => OrderPickerField(
                            value: controller.selectedAddress.value,
                            hint: 'أختر العنوان',
                            icon: Icons.location_on_outlined,
                            errorText: controller.addressError.value,
                            onTap: _openSavedAddresses,
                            trailing: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: AppColors.textSecondary,
                              size: 24.sp,
                            ),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: _openAddAddressFlow,
                            child: Text(
                              'أضافة عنوان جديد',
                              style: TextStyle(
                                fontFamily: 'Expo Arabic',
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.productStore,
                                decoration: TextDecoration.underline,
                                decorationColor: AppColors.productStore,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 22.h),
                        const OrderSectionTitle(title: 'طريقة الدفع'),
                        Obx(
                          () => PaymentMethodTile(
                            label: 'عند الأستلام',
                            selected:
                                controller.paymentMethod.value ==
                                PaymentMethod.onDelivery,
                            onTap: () => controller.selectPayment(
                              PaymentMethod.onDelivery,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              BasketBottomBar(label: 'التالي', onTap: controller.goToConfirm),
            ],
          );
        }),
      ),
    );
  }

  Future<void> _openSavedAddresses() async {
    final selected = await SavedAddressesPage.openForSelection();
    if (selected == null) return;
    controller.selectAddress(selected.formattedLine);
  }

  Future<void> _openAddAddressFlow() async {
    final selected = await SavedAddressesPage.openForSelection(
      openAddOnStart: true,
    );
    if (selected == null) return;
    controller.selectAddress(selected.formattedLine);
  }
}
