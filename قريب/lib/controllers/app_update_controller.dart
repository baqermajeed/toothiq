import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../controllers/auth_controller.dart';
import '../widgets/dialogs/update_available_dialog.dart';

/// يتحقق من إصدار التطبيق مع الـ API ويعرض دايلوغ التحديث عند الحاجة.
class AppUpdateController extends GetxController {
  @override
  void onReady() {
    super.onReady();
    SchedulerBinding.instance.addPostFrameCallback((_) => checkForUpdate());
  }

  /// يتحقق من التحديثات ويعرض الدايلوغ إن لزم.
  Future<void> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final version = packageInfo.version;
      final buildNumber = packageInfo.buildNumber;
      final fullVersion = '$version+$buildNumber';

      final auth = Get.find<AuthController>();
      final result = await auth.apiClient.getAppVersionCheck(fullVersion);

      if (result == null || !result.updateRequired) return;

      if (kDebugMode) {
        print('[AppUpdate] تحديث مطلوب: minimum=${result.minimumVersion}, force=${result.forceUpdate}');
      }

      UpdateAvailableDialog.show(
        storeUrl: result.storeUrl,
        forceUpdate: result.forceUpdate,
        minimumVersion: result.minimumVersion,
      );
    } catch (e, st) {
      if (kDebugMode) {
        print('[AppUpdate] خطأ أثناء التحقق: $e\n$st');
      }
    }
  }
}
