import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

import '../core/errors/api_exception.dart';
import '../utils/location_helper.dart';
import '../widgets/common/app_toast.dart';
import '../widgets/dialogs/location_permission_denied_dialog.dart';
import 'auth_controller.dart';

/// Controller لشاشة إضافة الموقع عند عدم توفيره أثناء المصادقة.
class LocationRequiredController extends GetxController {
  final isLoading = false.obs;
  final Rxn<String> errorMessage = Rxn<String>();

  AuthController get auth => Get.find<AuthController>();

  Future<void> useCurrentLocation() async {
    errorMessage.value = null;
    isLoading.value = true;
    try {
      final coords = await requestAndGetLocation();
      if (coords == null || coords.length < 2) {
        final permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          LocationPermissionDeniedDialog.show();
        } else {
          AppToast.show(
            'الموقع',
            'لم يتم الحصول على الموقع. تأكد من تفعيل خدمة الموقع.',
            type: ToastType.warning,
          );
        }
        return;
      }
      final updated = await auth.apiClient.updateMe(
        name: auth.user.value!.name,
        location: coords,
      );
      auth.user.value = updated;
      Get.offAllNamed('/home');
    } on ApiException catch (e) {
      errorMessage.value = e.message;
      AppToast.show('فشل', e.message, type: ToastType.error);
    } catch (_) {
      AppToast.show('فشل', 'حدث خطأ، حاول مرة أخرى', type: ToastType.error);
    } finally {
      isLoading.value = false;
    }
  }

  void skip() {
    Get.offAllNamed('/home');
  }
}
