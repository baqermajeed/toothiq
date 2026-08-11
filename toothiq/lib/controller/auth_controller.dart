import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/api/api_exception.dart';
import '../model/auth_session_model.dart';
import '../model/governorate_model.dart';
import '../service_layer/services/auth_service.dart';
import '../service_layer/services/governorate_service.dart';
import '../utils/phone_validator.dart';
import '../widget/dialogs/login_error_dialog.dart';
import '../view/main_page.dart';
import 'session_controller.dart';

class AuthController extends GetxController {
  final SessionController _session = Get.find<SessionController>();
  final AuthService _auth = Get.find<AuthService>();
  final GovernorateService _governorateService = Get.find<GovernorateService>();

  final TextEditingController loginPhoneCtrl = TextEditingController();
  final TextEditingController loginPasswordCtrl = TextEditingController();
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController registerPhoneCtrl = TextEditingController();
  final TextEditingController registerPasswordCtrl = TextEditingController();
  final TextEditingController confirmPasswordCtrl = TextEditingController();
  final TextEditingController clinicNameCtrl = TextEditingController();
  final TextEditingController governorateCtrl = TextEditingController();

  final RxString selectedGovernorateId = ''.obs;
  final RxList<GovernorateModel> governorates = <GovernorateModel>[].obs;
  final RxBool isLoadingGovernorates = false.obs;

  final RxnString loginPhoneError = RxnString();
  final RxnString loginPasswordError = RxnString();
  final RxnString registerPhoneError = RxnString();
  final RxnString nameError = RxnString();
  final RxnString governorateError = RxnString();
  final RxnString registerPasswordError = RxnString();
  final RxnString confirmPasswordError = RxnString();
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadGovernorates();
  }

  @override
  void onClose() {
    loginPhoneCtrl.dispose();
    loginPasswordCtrl.dispose();
    nameCtrl.dispose();
    registerPhoneCtrl.dispose();
    registerPasswordCtrl.dispose();
    confirmPasswordCtrl.dispose();
    clinicNameCtrl.dispose();
    governorateCtrl.dispose();
    super.onClose();
  }

  Future<void> _loadGovernorates() async {
    isLoadingGovernorates.value = true;
    try {
      governorates.assignAll(await _governorateService.fetchGovernorates());
    } catch (_) {
      governorates.clear();
    } finally {
      isLoadingGovernorates.value = false;
    }
  }

  void clearLoginErrors() {
    loginPhoneError.value = null;
    loginPasswordError.value = null;
  }

  void clearRegisterErrors() {
    nameError.value = null;
    registerPhoneError.value = null;
    governorateError.value = null;
    registerPasswordError.value = null;
    confirmPasswordError.value = null;
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

  bool _validatePassword(String password, RxnString errorHolder) {
    if (password.isEmpty) {
      errorHolder.value = '! كلمة المرور مطلوبة';
      return false;
    }
    if (password.length < 8) {
      errorHolder.value = '! كلمة المرور يجب أن تكون 8 أحرف على الأقل';
      return false;
    }
    errorHolder.value = null;
    return true;
  }

  Future<void> login() async {
    if (isLoading.value) return;
    clearLoginErrors();
    final phone = loginPhoneCtrl.text.trim();
    final password = loginPasswordCtrl.text;

    var valid = _validatePhone(phone, loginPhoneError);
    if (password.isEmpty) {
      loginPasswordError.value = '! كلمة المرور مطلوبة';
      valid = false;
    }
    if (!valid) return;

    isLoading.value = true;
    try {
      final session = await _auth.login(phone: phone, password: password);
      await _completeAuth(session);
    } on ApiException catch (error) {
      _showAuthError(error, isLogin: true);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> register() async {
    if (isLoading.value) return;
    clearRegisterErrors();
    var valid = true;

    if (nameCtrl.text.trim().isEmpty) {
      nameError.value = '! الاسم مطلوب';
      valid = false;
    }

    if (!_validatePhone(registerPhoneCtrl.text.trim(), registerPhoneError)) {
      valid = false;
    }

    if (selectedGovernorateId.value.isEmpty) {
      governorateError.value = '! اختر محافظتك';
      valid = false;
    }

    if (!_validatePassword(registerPasswordCtrl.text, registerPasswordError)) {
      valid = false;
    }

    if (confirmPasswordCtrl.text != registerPasswordCtrl.text) {
      confirmPasswordError.value = '! كلمتا المرور غير متطابقتين';
      valid = false;
    }

    if (!valid) return;

    isLoading.value = true;
    try {
      final session = await _auth.register(
        name: _formatDoctorName(nameCtrl.text.trim()),
        phone: registerPhoneCtrl.text.trim(),
        governorateId: selectedGovernorateId.value,
        password: registerPasswordCtrl.text,
        clinicName: clinicNameCtrl.text.trim(),
      );
      await _completeAuth(session);
    } on ApiException catch (error) {
      _showAuthError(error, isLogin: false);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _completeAuth(AuthSessionModel session) async {
    await _session.setSession(session);
    MainPage.open();
  }

  void _showAuthError(ApiException error, {required bool isLogin}) {
    final message = error.statusCode == 429
        ? 'تم تجاوز عدد محاولات تسجيل الدخول المسموحة مؤقتاً. انتظر دقيقة ثم حاول مرة أخرى.'
        : error.message;

    if (isLogin && error.statusCode == 401) {
      loginPasswordError.value = '! $message';
      return;
    }

    LoginErrorDialog.show(
      message,
      title: isLogin ? 'فشل تسجيل الدخول' : 'فشل إنشاء الحساب',
    );
  }

  String _formatDoctorName(String name) {
    if (name.startsWith('د.') || name.startsWith('د. ')) return name;
    return 'د. $name';
  }

  void pickGovernorate(GovernorateModel governorate) {
    selectedGovernorateId.value = governorate.id;
    governorateCtrl.text = governorate.nameAr;
    governorateError.value = null;
  }
}
