import 'package:get/get.dart';

import '../bindings/app_binding.dart';
import '../controller/session_controller.dart';
import '../core/utils/image_url.dart';
import '../model/shop_profile.dart';
import '../service_layer/services/shop_service.dart';

class ShopProfileController extends GetxController {
  ShopProfileController({
    required ShopService shopService,
    required SessionController session,
  }) : _shopService = shopService,
       _session = session;

  final ShopService _shopService;
  final SessionController _session;

  final profile = Rxn<ShopProfile>();
  final isLoading = false.obs;
  final isSaving = false.obs;
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadProfile();
  }

  Future<void> loadProfile() async {
    final shopId = _session.shopId.value;
    if (shopId.isEmpty) return;

    isLoading.value = true;
    errorMessage.value = '';
    try {
      final data = await _shopService.fetchProfile(shopId);
      profile.value = _withResolvedImages(data);
    } catch (error) {
      errorMessage.value = apiErrorMessage(error);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveProfile({
    required String name,
    required String description,
    required String address,
    required String phonePrimary,
    String? phoneSecondary,
    String? logoPath,
  }) async {
    final shopId = _session.shopId.value;
    if (shopId.isEmpty) {
      Get.snackbar('خطأ', 'معرّف المتجر غير متوفر');
      return;
    }

    isSaving.value = true;
    try {
      final updated = await _shopService.updateProfile(
        shopId: shopId,
        name: name,
        description: description,
        address: address,
        phonePrimary: phonePrimary,
        phoneSecondary: phoneSecondary,
        logoPath: logoPath,
      );
      profile.value = _withResolvedImages(updated);
      await _session.updateDisplayName(updated.name);
      Get.snackbar('تم', 'تم تحديث بيانات المتجر');
    } catch (error) {
      Get.snackbar('خطأ', apiErrorMessage(error));
    } finally {
      isSaving.value = false;
    }
  }

  ShopProfile _withResolvedImages(ShopProfile data) {
    final logo = data.logoPath;
    if (logo == null || logo.isEmpty || ImageUrl.isLocalFile(logo)) {
      return data;
    }
    return data.copyWith(logoPath: ImageUrl.resolve(logo));
  }
}
