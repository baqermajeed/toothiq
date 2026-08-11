import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../utils/location_helper.dart';
import '../widgets/dialogs/login_error_dialog.dart';
import 'auth_controller.dart';

/// Controller لشاشة إنشاء حساب: يحتفظ بحقول النص ويتولى dispose في onClose.
class RegisterController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();

  AuthController get auth => Get.find<AuthController>();

  Future<void> submit() async {
    auth.clearError();
    if (!formKey.currentState!.validate()) return;
    final password = passwordController.text;
    if (password.length < 8) {
      auth.clearError();
      return;
    }
    auth.isLoading.value = true;
    try {
      final location = await requestAndGetLocation();
      final ok = await auth.register(
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),
        password: password,
        location: location,
      );
      if (ok) {
        final user = auth.user.value;
        Get.offAllNamed(
          user?.hasValidLocation == true ? '/home' : '/location-required',
        );
      } else {
        final msg = auth.errorMessage.value ?? 'حدث خطأ، حاول مرة أخرى';
        LoginErrorDialog.show(msg, title: 'فشل إنشاء الحساب');
      }
    } catch (_) {
      final msg = auth.errorMessage.value ?? 'حدث خطأ، حاول مرة أخرى';
      LoginErrorDialog.show(msg, title: 'فشل إنشاء الحساب');
    } finally {
      auth.isLoading.value = false;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
