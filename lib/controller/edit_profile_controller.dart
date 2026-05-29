import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'settings_controller.dart';

class EditProfileController extends GetxController {
  final SettingsController settings = Get.find<SettingsController>();

  late final TextEditingController usernameController;
  late final TextEditingController phoneController;
  late final TextEditingController clinicController;

  final isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    final name = settings.userName.value;
    usernameController = TextEditingController(
      text: name.startsWith('د. ') ? name.substring(3) : name,
    );
    phoneController = TextEditingController(text: '0700 000 000');
    clinicController = TextEditingController(text: 'العيادة');
  }

  @override
  void onClose() {
    usernameController.dispose();
    phoneController.dispose();
    clinicController.dispose();
    super.onClose();
  }

  void onPickPhoto() {
    // TODO: اختيار صورة من المعرض أو الكاميرا
  }

  void save() {
    final name = usernameController.text.trim();
    if (name.isNotEmpty) {
      settings.userName.value = name.startsWith('د.') ? name : 'د. $name';
    }
    final clinic = clinicController.text.trim();
    if (clinic.isNotEmpty) {
      settings.userAddress.value = '$clinic ، بابل ، شارع 40';
    }
    Get.back();
  }

  void cancel() => Get.back();
}
