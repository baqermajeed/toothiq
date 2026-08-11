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
            return const AppLoadingState();
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
                            onTap: () => _showAddressPicker(context),
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
                            onTap: () => _showAddAddressDialog(context),
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
                        const OrderSectionTitle(title: 'وقت التوصيل'),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 3,
                              child: OrderFormField(
                                controller: controller.deliveryTimeCtrl,
                                hint: '00:00',
                                icon: Icons.schedule_outlined,
                                readOnly: true,
                                onTap: () =>
                                    controller.pickDeliveryTime(context),
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              flex: 2,
                              child: Obx(
                                () => OrderPickerField(
                                  value: controller.selectedPeriod.value,
                                  hint: 'مساءً',
                                  icon: Icons.wb_twilight_outlined,
                                  onTap: () => _showPeriodPicker(context),
                                  trailing: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: AppColors.textSecondary,
                                    size: 24.sp,
                                  ),
                                ),
                              ),
                            ),
                          ],
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
                        SizedBox(height: 10.h),
                        Obx(
                          () => PaymentMethodTile(
                            label: 'ماستر كارد',
                            selected:
                                controller.paymentMethod.value ==
                                PaymentMethod.mastercard,
                            onTap: () => controller.selectPayment(
                              PaymentMethod.mastercard,
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

  void _showAddressPicker(BuildContext context) {
    final addresses = controller.savedAddresses;
    if (addresses.isEmpty) {
      _showAddAddressDialog(context);
      return;
    }

    Get.bottomSheet(
      Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'أختر العنوان',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Expo Arabic',
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.productTitle,
                ),
              ),
              SizedBox(height: 16.h),
              ...addresses.map(
                (address) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    address,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: 'Expo Arabic',
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: Obx(
                    () => controller.selectedAddress.value == address
                        ? Icon(
                            Icons.check_circle,
                            color: AppColors.productStore,
                          )
                        : const SizedBox.shrink(),
                  ),
                  onTap: () {
                    controller.selectAddress(address);
                    Get.back();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showPeriodPicker(BuildContext context) {
    Get.bottomSheet(
      Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: controller.deliveryPeriods
                .map(
                  (period) => ListTile(
                    title: Text(
                      period,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: 'Expo Arabic',
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: Obx(
                      () => controller.selectedPeriod.value == period
                          ? Icon(
                              Icons.check_circle,
                              color: AppColors.productStore,
                            )
                          : const SizedBox.shrink(),
                    ),
                    onTap: () {
                      controller.selectPeriod(period);
                      Get.back();
                    },
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  Future<void> _showAddAddressDialog(BuildContext context) async {
    final addressCtrl = TextEditingController();
    final result = await Get.dialog<String>(
      Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(
            'عنوان جديد',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: 'Expo Arabic',
              fontWeight: FontWeight.w800,
            ),
          ),
          content: TextField(
            controller: addressCtrl,
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              hintText: 'أكتب العنوان',
              hintStyle: TextStyle(fontFamily: 'Expo Arabic'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('إلغاء', style: TextStyle(fontFamily: 'Expo Arabic')),
            ),
            TextButton(
              onPressed: () => Get.back(result: addressCtrl.text),
              child: Text(
                'حفظ',
                style: TextStyle(
                  fontFamily: 'Expo Arabic',
                  color: AppColors.productStore,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    addressCtrl.dispose();
    if (result != null && result.trim().isNotEmpty) {
      controller.addAddress(result);
    }
  }
}
