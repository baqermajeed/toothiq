import 'package:flutter/foundation.dart';

/// مساعد لتتبع خطوات الخريطة وتحديد نقطة التجمّد على iOS.
///
/// طريقة الاستخدام:
/// 1. افتح المشروع في Xcode: open ios/Runner.xcworkspace
/// 2. اختر جهازك الحقيقي واضرِب Run (أو من الطرفية: flutter run)
/// 3. افتح الخريطة في التطبيق حتى يتجمّد
/// 4. راقب الكونسول — آخر سطر يبدأ بـ [MAP_DEBUG] قبل التجمّد هو مكان المشكلة
///
/// توزيع الخطوات:
/// - ICON_FROM_SVG_START / PICTURE_TO_IMAGE_START: تحميل SVG أو تحويل صورة (قد يتجمّد هنا)
/// - GOOGLE_MAP_BUILD_START: بدء بناء widget الخريطة
/// - ON_MAP_CREATED: الخريطة جاهزة — إذا لم يظهر فالمشكلة في الطبقة الأصلية
class MapDebugLogger {
  static const String _tag = '[MAP_DEBUG]';
  static bool _enabled = kDebugMode; // يعمل في وضع التطوير فقط

  static void enable() => _enabled = true;
  static void disable() => _enabled = false;

  static void _log(String step, [String? extra]) {
    if (!_enabled) return;
    final ts = DateTime.now().toIso8601String();
    final msg = extra != null ? '$step | $extra' : step;
    // استخدام print للضمان ظهور السجلات فوراً في Xcode console
    print('$_tag $ts | $msg');
    debugPrint('$_tag $ts | $msg');
  }

  /// دخول شاشة الخريطة
  static void screenEnter(String screenName) =>
      _log('SCREEN_ENTER', screenName);

  /// خروج من شاشة الخريطة
  static void screenExit(String screenName) =>
      _log('SCREEN_EXIT', screenName);

  /// بداية تحميل أيقونات الخريطة
  static void iconsLoadStart() => _log('ICONS_LOAD_START');

  /// بداية تحميل أيقونة من Icon
  static void iconFromIconStart() => _log('ICON_FROM_ICON_START');

  /// انتهاء تحميل أيقونة من Icon
  static void iconFromIconEnd() => _log('ICON_FROM_ICON_END');

  /// بداية تحميل أيقونة من SVG
  static void iconFromSvgStart(String path) =>
      _log('ICON_FROM_SVG_START', path);

  /// تحميل نص SVG
  static void svgStringLoaded() => _log('SVG_STRING_LOADED');

  /// رسم صورة SVG
  static void svgPictureDrawn() => _log('SVG_PICTURE_DRAWN');

  /// تحويل Picture إلى Image (قد يتجمّد هنا على iOS)
  static void pictureToImageStart() => _log('PICTURE_TO_IMAGE_START');

  /// انتهاء تحويل Picture إلى Image
  static void pictureToImageEnd() => _log('PICTURE_TO_IMAGE_END');

  /// تحويل إلى ByteData
  static void toByteDataStart() => _log('TO_BYTEDATA_START');

  /// انتهاء تحويل ByteData
  static void toByteDataEnd() => _log('TO_BYTEDATA_END');

  /// انتهاء تحميل كل الأيقونات
  static void iconsLoadEnd() => _log('ICONS_LOAD_END');

  /// بناء GoogleMap widget
  static void googleMapBuildStart() => _log('GOOGLE_MAP_BUILD_START');

  /// انتهاء بناء GoogleMap
  static void googleMapBuildEnd() => _log('GOOGLE_MAP_BUILD_END');

  /// onMapCreated استُدعي
  static void onMapCreated() => _log('ON_MAP_CREATED');

  /// خطأ
  static void error(String step, Object e, [StackTrace? st]) {
    _log('ERROR', '$step: $e');
    if (st != null) {
      print('$_tag STACK: $st');
    }
  }
}
