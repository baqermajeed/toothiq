import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../core/api/api_client.dart';
import '../view/main_page.dart';
import '../widget/dialogs/update_available_dialog.dart';

/// يتحقق من إصدار التطبيق مع الـ API ويعرض دايلوغ التحديث عند الحاجة.
class AppUpdateController extends GetxController {
  final ApiClient _api = Get.find<ApiClient>();

  bool _isChecking = false;
  bool _dialogVisible = false;

  /// يُستدعى بعد استقرار الصفحة الرئيسية — لا من onReady أثناء الـ splash.
  Future<void> checkForUpdate() async {
    if (_isChecking || _dialogVisible) return;
    _isChecking = true;

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

      await _showWhenMainReady(
        storeUrl: result.storeUrl,
        forceUpdate: result.forceUpdate,
        minimumVersion: result.minimumVersion,
      );
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('[AppUpdate] خطأ أثناء التحقق: $error\n$stackTrace');
      }
    } finally {
      _isChecking = false;
    }
  }

  Future<void> _showWhenMainReady({
    required String storeUrl,
    required bool forceUpdate,
    String? minimumVersion,
  }) async {
    // انتظر انتهاء الانتقالات (splash → main) قبل فتح الدايلوغ.
    for (var i = 0; i < 40; i++) {
      final routeName = Get.rawRoute?.settings.name;
      final onMain = routeName == MainPage.routeName;
      if (onMain && Get.isDialogOpen != true) {
        break;
      }
      await Future.delayed(const Duration(milliseconds: 50));
    }

    if (_dialogVisible || Get.isDialogOpen == true) return;
    if (Get.rawRoute?.settings.name != MainPage.routeName) return;

    _dialogVisible = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (Get.rawRoute?.settings.name != MainPage.routeName) {
        _dialogVisible = false;
        return;
      }
      UpdateAvailableDialog.show(
        storeUrl: storeUrl,
        forceUpdate: forceUpdate,
        minimumVersion: minimumVersion,
      ).whenComplete(() {
        _dialogVisible = false;
      });
    });
  }
}
