import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../core/api/api_exception.dart';
import '../widget/common/app_toast.dart';
import '../widget/dialogs/photos_permission_denied_dialog.dart';
import 'settings_controller.dart';

class EditProfileController extends GetxController {
  final SettingsController settings = Get.find<SettingsController>();
  final ImagePicker _imagePicker = ImagePicker();

  late final TextEditingController usernameController;
  late final TextEditingController phoneController;
  late final TextEditingController clinicController;

  final isSaving = false.obs;
  final profileImagePath = RxnString();

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
    profileImagePath.value = settings.profileImagePath.value;
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

  Future<void> onPickPhoto() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (picked == null) return;

      final storedPath = await _persistProfileImage(picked);
      profileImagePath.value = storedPath;
      await settings.saveProfileImagePath(storedPath);
    } on PlatformException catch (error) {
      if (_isPhotoPermissionDenied(error)) {
        PhotosPermissionDeniedDialog.show();
        return;
      }
      AppToast.show(
        'تعذر فتح المعرض',
        'تأكد من السماح بالوصول إلى الصور ثم حاول مرة أخرى',
        type: ToastType.error,
      );
    } catch (_) {
      AppToast.show(
        'تعذر فتح المعرض',
        'حاول مرة أخرى',
        type: ToastType.error,
      );
    }
  }

  Future<String> _persistProfileImage(XFile picked) async {
    final appDir = await getApplicationDocumentsDirectory();
    final profileDir = Directory('${appDir.path}/profile_images');
    if (!await profileDir.exists()) {
      await profileDir.create(recursive: true);
    }

    final ext = picked.path.contains('.')
        ? picked.path.substring(picked.path.lastIndexOf('.'))
        : '.jpg';
    final targetPath =
        '${profileDir.path}/profile_${DateTime.now().millisecondsSinceEpoch}$ext';
    await File(picked.path).copy(targetPath);
    return targetPath;
  }

  bool _isPhotoPermissionDenied(PlatformException error) {
    const deniedCodes = {
      'photo_access_denied',
      'camera_access_denied',
      'access_denied',
      'permission_denied',
    };
    return deniedCodes.contains(error.code);
  }

  Future<void> save() async {
    if (isSaving.value) return;

    final name = usernameController.text.trim();
    final phone = phoneController.text.trim();
    final clinic = clinicController.text.trim();

    final displayName = name.isEmpty
        ? settings.userName.value
        : (name.startsWith('د.') ? name : 'د. $name');

    final address = clinic.isEmpty
        ? settings.userAddress.value
        : '$clinic ، بابل ، شارع 40';

    isSaving.value = true;

    String toastTitle = 'تعذر حفظ التعديل';
    String toastMessage = 'حاول مرة أخرى';
    var toastType = ToastType.error;
    var closeSheet = false;

    try {
      await settings.saveProfile(
        name: displayName,
        phone: phone.isEmpty ? null : phone,
        address: address,
      );
      if (profileImagePath.value != null) {
        await settings.saveProfileImagePath(profileImagePath.value);
      }

      await settings
          .updateProfileOnApi(
            name: displayName,
            clinicName: clinic,
          )
          .timeout(const Duration(seconds: 20));

      closeSheet = true;
      toastTitle = 'تم الحفظ';
      toastMessage = 'تم تحديث معلوماتك بنجاح';
      toastType = ToastType.success;
    } on TimeoutException {
      closeSheet = true;
      toastTitle = 'تم الحفظ محلياً';
      toastMessage = 'تعذر مزامنة البيانات مع الخادم، حاول لاحقاً';
      toastType = ToastType.warning;
    } on ApiException catch (error) {
      toastTitle = 'تعذر حفظ التعديل';
      toastMessage = error.message;
      toastType = ToastType.error;
    } catch (_) {
      toastTitle = 'تعذر حفظ التعديل';
      toastMessage = 'حاول مرة أخرى';
      toastType = ToastType.error;
    }

    isSaving.value = false;

    if (closeSheet) {
      Get.back();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppToast.show(
        toastTitle,
        toastMessage,
        type: toastType,
      );
    });
  }

  void cancel() => Get.back();
}
