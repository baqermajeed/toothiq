import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../view/basket/checkout_confirm_page.dart';
import '../view/basket/new_order_page.dart';
import '../view/basket/order_success_page.dart';
import '../widget/basket/delivery_time_picker.dart';
import 'cart_controller.dart';
import 'settings_controller.dart';

enum CheckoutStep { delivery, confirm, success }

enum PaymentMethod { onDelivery, mastercard }

class CheckoutController extends GetxController {
  final currentStep = CheckoutStep.delivery.obs;

  final customerNameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final altPhoneCtrl = TextEditingController();
  final deliveryTimeCtrl = TextEditingController(text: '00:00');

  final customerNameError = RxnString();
  final phoneError = RxnString();
  final addressError = RxnString();

  final savedAddresses = <String>[].obs;
  final selectedAddress = RxnString();

  final deliveryPeriods = const ['صباحاً', 'ظهراً', 'مساءً'];
  final selectedPeriod = 'مساءً'.obs;

  final paymentMethod = PaymentMethod.onDelivery.obs;

  final isSubmitting = false.obs;

  CartController get cart => Get.find<CartController>();

  @override
  void onInit() {
    super.onInit();
    _loadProfileFromSettings();
  }

  @override
  void onClose() {
    customerNameCtrl.dispose();
    phoneCtrl.dispose();
    altPhoneCtrl.dispose();
    deliveryTimeCtrl.dispose();
    super.onClose();
  }

  void _loadProfileFromSettings() {
    if (!Get.isRegistered<SettingsController>()) {
      Get.lazyPut<SettingsController>(() => SettingsController());
    }
    final settings = Get.find<SettingsController>();

    final name = settings.displayNameForForms;
    if (name.isNotEmpty) {
      customerNameCtrl.text = name;
    }

    final phone = settings.userPhone.value.trim();
    if (phone.isNotEmpty) {
      phoneCtrl.text = phone;
    }

    final altPhone = settings.userAltPhone.value.trim();
    if (altPhone.isNotEmpty) {
      altPhoneCtrl.text = altPhone;
    }

    final address = settings.userAddress.value.trim();
    if (address.isNotEmpty) {
      if (!savedAddresses.contains(address)) {
        savedAddresses.add(address);
      }
      selectedAddress.value = address;
    }
  }

  void startCheckout() {
    if (cart.isEmpty) return;
    currentStep.value = CheckoutStep.delivery;
    _loadProfileFromSettings();
    NewOrderPage.open();
  }

  void selectAddress(String address) {
    selectedAddress.value = address;
    addressError.value = null;
  }

  void addAddress(String address) {
    final trimmed = address.trim();
    if (trimmed.isEmpty) return;
    if (!savedAddresses.contains(trimmed)) {
      savedAddresses.add(trimmed);
    }
    selectAddress(trimmed);
    if (Get.isRegistered<SettingsController>()) {
      Get.find<SettingsController>().saveProfile(address: trimmed);
    }
  }

  void selectPeriod(String period) {
    selectedPeriod.value = period;
  }

  void selectPayment(PaymentMethod method) {
    paymentMethod.value = method;
  }

  Future<void> pickDeliveryTime(BuildContext context) async {
    final parts = deliveryTimeCtrl.text.split(':');
    final initial = TimeOfDay(
      hour: parts.length == 2 ? int.tryParse(parts[0]) ?? 0 : 0,
      minute: parts.length == 2 ? int.tryParse(parts[1]) ?? 0 : 0,
    );
    final picked = await DeliveryTimePicker.show(
      context,
      initialTime: initial,
    );
    if (picked == null) return;
    final hour = picked.hour.toString().padLeft(2, '0');
    final minute = picked.minute.toString().padLeft(2, '0');
    deliveryTimeCtrl.text = '$hour:$minute';
  }

  bool _validateDeliveryForm() {
    customerNameError.value = null;
    phoneError.value = null;
    addressError.value = null;

    var valid = true;
    if (customerNameCtrl.text.trim().isEmpty) {
      customerNameError.value = 'أدخل اسم الزبون';
      valid = false;
    }
    if (phoneCtrl.text.trim().length < 10) {
      phoneError.value = 'رقم الهاتف غير صحيح !';
      valid = false;
    }
    if ((selectedAddress.value ?? '').trim().isEmpty) {
      addressError.value = 'أدخل عنوان التوصيل';
      valid = false;
    }
    return valid;
  }

  Future<void> goToConfirm() async {
    if (!_validateDeliveryForm()) return;

    if (Get.isRegistered<SettingsController>()) {
      final settings = Get.find<SettingsController>();
      final name = customerNameCtrl.text.trim();
      await settings.saveProfile(
        name: name.startsWith('د.') ? name : 'د. $name',
        phone: phoneCtrl.text.trim(),
        altPhone: altPhoneCtrl.text.trim(),
        address: selectedAddress.value,
      );
    }

    currentStep.value = CheckoutStep.confirm;
    CheckoutConfirmPage.open();
  }

  String get paymentMethodLabel => paymentMethod.value == PaymentMethod.onDelivery
      ? 'عند الأستلام'
      : 'ماستر كارد';

  String get deliveryTimeLabel =>
      '${deliveryTimeCtrl.text.trim()} ${selectedPeriod.value}';

  Future<void> submitOrder() async {
    if (isSubmitting.value) return;
    isSubmitting.value = true;
    await Future<void>.delayed(const Duration(milliseconds: 900));
    isSubmitting.value = false;
    cart.clearCart();
    currentStep.value = CheckoutStep.success;
    Get.offAll(() => const OrderSuccessPage());
  }

  int get stepIndex {
    switch (currentStep.value) {
      case CheckoutStep.delivery:
        return 0;
      case CheckoutStep.confirm:
        return 1;
      case CheckoutStep.success:
        return 2;
    }
  }
}
