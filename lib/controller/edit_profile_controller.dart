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
    usernameController = TextEditingController(
      text: settings.displayNameForForms,
    );
    phoneController = TextEditingController(text: settings.userPhone.value);
    clinicController = TextEditingController(
      text: _clinicFromAddress(settings.userAddress.value),
    );
  }

  String _clinicFromAddress(String address) {
    final parts = address.split('،');
    if (parts.isEmpty) return '';
    return parts.first.trim();
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

  Future<void> save() async {
    final name = usernameController.text.trim();
    final phone = phoneController.text.trim();
    final clinic = clinicController.text.trim();

    final displayName = name.isEmpty
        ? settings.userName.value
        : (name.startsWith('د.') ? name : 'د. $name');

    final address = clinic.isEmpty
        ? settings.userAddress.value
        : '$clinic ، بابل ، شارع 40';

    await settings.saveProfile(
      name: displayName,
      phone: phone.isEmpty ? null : phone,
      address: address,
    );

    Get.back();
  }

  void cancel() => Get.back();
}
