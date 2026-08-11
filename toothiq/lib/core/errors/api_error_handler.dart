import 'package:flutter/foundation.dart';

import '../api/api_exception.dart';
import '../../widget/common/app_toast.dart';
import '../../widget/dialogs/voice_order_only_dialog.dart';
import '../../widget/dialogs/zone_not_supported_dialog.dart';

/// معالجة موحّدة لأخطاء الـ API — نفس نهج قريب (حوارات المنطقة + Toast).
abstract final class ApiErrorHandler {
  /// يعرض الخطأ المناسب لعمليات الطلب (منطقة / طلب صوتي / Toast).
  static void showOrderError(
    ApiException error, {
    String title = 'فشل الطلب',
  }) {
    if (ApiException.isZoneError(error)) {
      ZoneNotSupportedDialog.show(subtitle: error.message);
      return;
    }
    if (ApiException.isVoiceOrderOnlyError(error)) {
      VoiceOrderOnlyDialog.show();
      return;
    }
    AppToast.show(title, error.message, type: ToastType.error);
  }

  /// Toast عام لأخطاء الـ API.
  static void showApiError(
    ApiException error, {
    String title = 'خطأ',
  }) {
    AppToast.show(title, error.message, type: ToastType.error);
  }

  /// رسالة مناسبة للعرض في `loadError` داخل الـ controllers.
  static String loadMessage(
    Object error, {
    String fallback = 'تعذر تحميل البيانات',
  }) {
    if (error is ApiException) return error.message;
    if (kDebugMode) debugPrint('[ApiErrorHandler] $error');
    return fallback;
  }
}
