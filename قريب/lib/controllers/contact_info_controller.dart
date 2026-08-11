import 'package:get/get.dart';

import 'auth_controller.dart';
import '../models/contact_info.dart';
import '../services/api_client.dart';

/// جلب معلومات التواصل (فيسبوك، انستغرام، رقم الدعم) عند النقر وفتح الرابط أو واتساب.
class ContactInfoController extends GetxController {
  final contactInfo = Rxn<ContactInfo>();
  final isLoading = false.obs;

  ApiClient get _api => Get.find<AuthController>().apiClient;

  /// جلب البيانات من الـ API (عند النقر على أحد الأزرار).
  Future<ContactInfo> loadContactInfo() async {
    if (contactInfo.value != null && !isLoading.value) {
      return contactInfo.value!;
    }
    isLoading.value = true;
    try {
      final info = await _api.getContactInfo();
      contactInfo.value = info;
      return info;
    } finally {
      isLoading.value = false;
    }
  }
}
