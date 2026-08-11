import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../core/api/api_exception.dart';
import '../core/errors/api_error_handler.dart';
import '../view/basket/checkout_confirm_page.dart';
import '../view/basket/new_order_page.dart';
import '../view/main_page.dart';
import '../widget/common/app_toast.dart';
import '../widget/dialogs/app_dialogs.dart';
import '../widget/dialogs/delivery_location_required_dialog.dart';
import '../widget/dialogs/order_success_dialog.dart';
import '../service_layer/services/platform_settings_service.dart';
import '../widget/settings/address_form_bottom_sheet.dart';
import 'cart_controller.dart';
import 'saved_addresses_controller.dart';
import 'session_controller.dart';
import 'settings_controller.dart';

enum CheckoutStep { delivery, confirm, success }

enum PaymentMethod { onDelivery }

class CheckoutController extends GetxController {
  final currentStep = CheckoutStep.delivery.obs;

  final customerNameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final altPhoneCtrl = TextEditingController();

  final customerNameError = RxnString();
  final phoneError = RxnString();
  final addressError = RxnString();

  final savedAddresses = <String>[].obs;
  final selectedAddress = RxnString();
  final SavedAddressesController _savedAddressesController =
      Get.find<SavedAddressesController>();

  final paymentMethod = PaymentMethod.onDelivery.obs;

  final isInitializing = false.obs;
  final isSubmitting = false.obs;
  final loadError = RxnString();
  final submitError = RxnString();

  CartController get cart => Get.find<CartController>();

  @override
  void onInit() {
    super.onInit();
    initializeCheckout();
  }

  @override
  void onClose() {
    customerNameCtrl.dispose();
    phoneCtrl.dispose();
    altPhoneCtrl.dispose();
    super.onClose();
  }

  void _loadProfileFromSettings() {
    if (!Get.isRegistered<SettingsController>()) {
      Get.lazyPut<SettingsController>(() => SettingsController());
    }
    final settings = Get.find<SettingsController>();
    final sessionUser = Get.isRegistered<SessionController>()
        ? Get.find<SessionController>().user.value
        : null;

    final name = settings.displayNameForForms;
    if (name.isNotEmpty) {
      customerNameCtrl.text = name;
    } else if ((sessionUser?.name.trim() ?? '').isNotEmpty) {
      customerNameCtrl.text = sessionUser!.name.trim();
    }

    final phone = settings.userPhone.value.trim();
    if (phone.isNotEmpty) {
      phoneCtrl.text = phone;
    } else if ((sessionUser?.phone.trim() ?? '').isNotEmpty) {
      phoneCtrl.text = sessionUser!.phone.trim();
    }

    final altPhone = settings.userAltPhone.value.trim();
    if (altPhone.isNotEmpty) {
      altPhoneCtrl.text = altPhone;
    }

    _syncSavedAddresses();

    if ((selectedAddress.value ?? '').trim().isEmpty) {
      final profileAddress = settings.userAddress.value.trim();
      if (profileAddress.isNotEmpty) {
        selectedAddress.value = profileAddress;
      } else if (sessionUser != null) {
        final governorate = sessionUser.governorateId.trim();
        final clinic = (sessionUser.clinicName ?? '').trim();
        final fallbackAddress = [governorate, clinic]
            .where((part) => part.isNotEmpty)
            .join(' ، ');
        if (fallbackAddress.isNotEmpty) {
          selectedAddress.value = fallbackAddress;
        }
      }
    }
  }

  void _syncSavedAddresses() {
    final items = _savedAddressesController.addresses;
    savedAddresses.assignAll(
      items.map((address) => address.formattedLine).where((line) => line.isNotEmpty),
    );

    final current = items.firstWhereOrNull((address) => address.isCurrent);
    if (current != null && current.formattedLine.isNotEmpty) {
      selectedAddress.value = current.formattedLine;
      return;
    }

    if (savedAddresses.isNotEmpty && (selectedAddress.value ?? '').isEmpty) {
      selectedAddress.value = savedAddresses.first;
    }
  }

  Future<void> initializeCheckout() async {
    isInitializing.value = true;
    loadError.value = null;
    try {
      await Get.find<PlatformSettingsService>().refresh();
      final sessionUser = Get.isRegistered<SessionController>()
          ? Get.find<SessionController>().user.value
          : null;
      final sessionUserId = sessionUser?.id.trim() ?? '';
      if (sessionUserId.isNotEmpty) {
        await _savedAddressesController.bindToUser(sessionUserId);
      }
      _loadProfileFromSettings();
    } catch (_) {
      loadError.value = 'تعذر تحميل بيانات الطلب';
    } finally {
      isInitializing.value = false;
    }
  }

  @override
  Future<void> refresh() async {
    await initializeCheckout();
  }

  void startCheckout() {
    if (cart.isEmpty) return;
    currentStep.value = CheckoutStep.delivery;
    submitError.value = null;
    initializeCheckout();
    NewOrderPage.open();
  }

  void selectAddress(String address) {
    selectedAddress.value = address;
    addressError.value = null;

    final match = _savedAddressesController.addresses.firstWhereOrNull(
      (item) => item.formattedLine == address,
    );
    if (match != null) {
      _savedAddressesController.setCurrentAddress(match.id);
    }
  }

  Future<void> addAddressFromForm(AddressFormResult result) async {
    await _savedAddressesController.addAddress(
      governorate: result.governorate,
      area: result.area,
      landmark: result.landmark,
      lat: result.lat,
      lng: result.lng,
      setAsCurrent: true,
    );
    _syncSavedAddresses();

    final current = _savedAddressesController.addresses.firstWhereOrNull(
      (item) => item.isCurrent,
    );
    if (current != null && current.formattedLine.isNotEmpty) {
      selectAddress(current.formattedLine);
    }
  }

  void selectPayment(PaymentMethod method) {
    paymentMethod.value = method;
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
    submitError.value = null;

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

  String get paymentMethodLabel => 'عند الأستلام';

  Future<void> submitOrder() async {
    if (isSubmitting.value) return;
    if (cart.isEmpty) {
      AppToast.show(
        'السلة فارغة',
        'أضف منتجات قبل إتمام الطلب',
        type: ToastType.warning,
      );
      return;
    }

    final deliveryAddress = (selectedAddress.value ?? '').trim();
    if (deliveryAddress.isEmpty) {
      addressError.value = 'أدخل عنوان التوصيل';
      return;
    }

    if (!cart.hasDeliveryCoordinates) {
      DeliveryLocationRequiredDialog.show();
      return;
    }

    isSubmitting.value = true;
    submitError.value = null;
    AppDialogs.showLoading('جاري إرسال الطلب...');
    try {
      final match = _savedAddressesController.addresses.firstWhereOrNull(
        (item) => item.formattedLine == deliveryAddress,
      );
      final orderId = await cart.completeOrderFromCart(
        deliveryAddress: deliveryAddress,
        lat: match?.lat,
        lng: match?.lng,
        clearAfterSuccess: false,
      );

      AppDialogs.hideLoading();

      currentStep.value = CheckoutStep.success;
      MainPage.returnFromCheckout();
      cart.clearCart();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        showOrderSuccessDialog(orderId: orderId);
      });
    } on ApiException catch (error) {
      submitError.value = error.message;
      AppDialogs.hideLoading();
      if (error.message.contains('موقع التوصيل')) {
        DeliveryLocationRequiredDialog.show();
      } else {
        ApiErrorHandler.showOrderError(error);
      }
    } catch (_) {
      submitError.value = 'تعذر إرسال الطلب، حاول مرة أخرى';
      AppDialogs.hideLoading();
      AppToast.show(
        'فشل الطلب',
        'حدث خطأ، حاول مرة أخرى',
        type: ToastType.error,
      );
    } finally {
      AppDialogs.hideLoading();
      isSubmitting.value = false;
    }
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
