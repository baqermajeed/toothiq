import 'package:get/get.dart';

import 'app_location_controller.dart';
import 'auth_controller.dart';
import '../models/shop.dart';
import '../widgets/dialogs/voice_order_only_dialog.dart';
import '../widgets/dialogs/zone_not_supported_dialog.dart';

/// تحكم قسم «محلات قريبة منك» في الصفحة الرئيسية.
class HomeShopsController extends GetxController {
  final RxList<Shop> shops = <Shop>[].obs;
  final RxBool loading = true.obs;
  final Rxn<String> error = Rxn<String>();

  /// true عندما تكون المنطقة تدعم الطلب الصوتي فقط (بدون محلات).
  final RxBool isVoiceOrderOnlyZone = false.obs;

  /// تجنّب إظهار الدايلوج مرات متعددة في نفس الجلسة.
  bool hasShownZoneNotSupportedDialog = false;

  @override
  void onInit() {
    super.onInit();
    loadShops();
  }

  Future<void> loadShops() async {
    loading.value = true;
    error.value = null;
    isVoiceOrderOnlyZone.value = false;
    try {
      final auth = Get.find<AuthController>();
      final apiClient = auth.apiClient;
      double? lng;
      double? lat;
      final user = auth.user.value;
      if (user?.location is Map<String, dynamic>) {
        final loc = user!.location as Map<String, dynamic>;
        final coords = loc['coordinates'];
        if (coords is List && coords.length >= 2) {
          lng = (coords[0] as num).toDouble();
          lat = (coords[1] as num).toDouble();
        }
      }
      if (lng == null || lat == null) {
        final appLoc = Get.find<AppLocationController>();
        if (appLoc.hasLocation) {
          lng = appLoc.lng;
          lat = appLoc.lat;
        }
      }
      final list = await apiClient.getShops(lng: lng, lat: lat);
      shops.value = list;
      if (list.isEmpty && lng != null && lat != null) {
        final check = await apiClient.checkVoiceOrderZone(lng, lat);
        isVoiceOrderOnlyZone.value = check.inside;
      }
      loading.value = false;
    } catch (e) {
      error.value = e.toString().replaceFirst('ApiException', '').trim();
      if (error.value?.isEmpty ?? true) error.value = 'فشل تحميل المحلات';
      shops.clear();
      isVoiceOrderOnlyZone.value = false;
      loading.value = false;
    }
  }

  /// يعرض دايلوج «منطقتك تدعم فقط الطلبات الصوتية» أو «منطقتك غير مدعومة» (مرة واحدة في الجلسة).
  void maybeShowZoneNotSupportedDialog() {
    if (shops.isEmpty &&
        !loading.value &&
        error.value == null &&
        !hasShownZoneNotSupportedDialog) {
      hasShownZoneNotSupportedDialog = true;
      if (isVoiceOrderOnlyZone.value) {
        VoiceOrderOnlyDialog.show();
      } else {
        ZoneNotSupportedDialog.show();
      }
    }
  }

  /// إظهار الدايلوج يدوياً (مثلاً عند الضغط على الحالة الفارغة).
  void showZoneNotSupportedDialog() {
    if (isVoiceOrderOnlyZone.value) {
      VoiceOrderOnlyDialog.show();
    } else {
      ZoneNotSupportedDialog.show();
    }
  }
}
