import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../utils/location_helper.dart';
import '../widgets/dialogs/login_error_dialog.dart';
import 'auth_controller.dart';

/// Controller لشاشة تسجيل الدخول: يحتفظ بحقول النص ويتولى dispose في onClose.
class LoginController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();

  AuthController get auth => Get.find<AuthController>();

  Future<void> submit() async {
    auth.clearError();
    if (!formKey.currentState!.validate()) return;
    // إظهار التحميل فوراً حتى أثناء طلب الموقع (قد يستغرق ثوانٍ) لئلا يبدو التطبيق متجمداً
    auth.isLoading.value = true;
    try {
      final location = await requestAndGetLocation();
      final ok = await auth.login(
        phoneController.text.trim(),
        passwordController.text,
        location: location,
      );
      if (ok) {
        final user = auth.user.value;
        Get.offAllNamed(
          user?.hasValidLocation == true ? '/home' : '/location-required',
        );
      } else {
        final msg = auth.errorMessage.value ?? 'حدث خطأ، حاول مرة أخرى';
        LoginErrorDialog.show(msg);
      }
    } catch (_) {
      final msg = auth.errorMessage.value ?? 'حدث خطأ، حاول مرة أخرى';
      LoginErrorDialog.show(msg);
    } finally {
      auth.isLoading.value = false;
    }
  }

  @override
  void onClose() {
    phoneController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
