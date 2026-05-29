import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../utils/phone_validator.dart';
import '../view/main_page.dart';
import 'session_controller.dart';

class AuthController extends GetxController {
  final SessionController _session = Get.find<SessionController>();

  final TextEditingController loginPhoneCtrl = TextEditingController();
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController registerPhoneCtrl = TextEditingController();
  final TextEditingController clinicNameCtrl = TextEditingController();
  final TextEditingController governorateCtrl = TextEditingController();

  final RxString selectedGovernorate = ''.obs;
  final RxnString loginPhoneError = RxnString();
  final RxnString registerPhoneError = RxnString();
  final RxnString nameError = RxnString();
  final RxnString governorateError = RxnString();
  final RxBool isLoading = false.obs;

  @override
  void onClose() {
    loginPhoneCtrl.dispose();
    nameCtrl.dispose();
    registerPhoneCtrl.dispose();
    clinicNameCtrl.dispose();
    governorateCtrl.dispose();
    super.onClose();
  }

  void clearLoginErrors() {
    loginPhoneError.value = null;
  }

  void clearRegisterErrors() {
    nameError.value = null;
    registerPhoneError.value = null;
    governorateError.value = null;
  }

  bool _validatePhone(String phone, RxnString errorHolder) {
    if (phone.trim().isEmpty) {
      errorHolder.value = '! رقم الهاتف غير صحيح';
      return false;
    }
    if (!PhoneValidator.isValidIraqiPhone(phone)) {
      errorHolder.value = '! رقم الهاتف غير صحيح';
      return false;
    }
    errorHolder.value = null;
    return true;
  }

  Future<void> login() async {
    clearLoginErrors();
    final phone = loginPhoneCtrl.text.trim();
    if (!_validatePhone(phone, loginPhoneError)) return;

    isLoading.value = true;
    await Future.delayed(const Duration(milliseconds: 600));
    isLoading.value = false;

    // TODO: ربط API تسجيل الدخول عند التوفر
    _session.setToken('pending_api_${PhoneValidator.normalize(phone)}');
    Get.offAll(() => const MainPage());
  }

  Future<void> register() async {
    clearRegisterErrors();
    var valid = true;

    if (nameCtrl.text.trim().isEmpty) {
      nameError.value = '! الاسم مطلوب';
      valid = false;
    }

    if (!_validatePhone(registerPhoneCtrl.text.trim(), registerPhoneError)) {
      valid = false;
    }

    if (selectedGovernorate.value.isEmpty) {
      governorateError.value = '! اختر محافظتك';
      valid = false;
    }

    if (!valid) return;

    isLoading.value = true;
    await Future.delayed(const Duration(milliseconds: 800));
    isLoading.value = false;

    // TODO: ربط API إنشاء الحساب عند التوفر
    Get.snackbar(
      'تم',
      'تم إنشاء الحساب — سيتم الربط مع الخادم لاحقاً',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
    );
    Get.offAll(() => const MainPage());
  }

  void pickGovernorate(String governorate) {
    selectedGovernorate.value = governorate;
    governorateCtrl.text = governorate;
    governorateError.value = null;
  }
}
