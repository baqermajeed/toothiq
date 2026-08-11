import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../core/api/api_client.dart';
import '../widget/dialogs/update_available_dialog.dart';

/// يتحقق من إصدار التطبيق مع الـ API ويعرض دايلوغ التحديث عند الحاجة.
class AppUpdateController extends GetxController {
  final ApiClient _api = Get.find<ApiClient>();

  @override
  void onReady() {
    super.onReady();
    SchedulerBinding.instance.addPostFrameCallback((_) => checkForUpdate());
  }

  Future<void> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final fullVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
      final result = await _api.getAppVersionCheck(fullVersion);
      if (result == null || !result.updateRequired) return;

      if (kDebugMode) {
        debugPrint(
          '[AppUpdate] تحديث مطلوب: minimum=${result.minimumVersion}, force=${result.forceUpdate}',
        );
      }

      UpdateAvailableDialog.show(
        storeUrl: result.storeUrl,
        forceUpdate: result.forceUpdate,
        minimumVersion: result.minimumVersion,
      );
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('[AppUpdate] خطأ أثناء التحقق: $error\n$stackTrace');
      }
    }
  }
}
