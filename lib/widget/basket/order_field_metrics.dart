import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../utils/app_colors.dart';

/// مقاسات حقول صفحة طلب منتج — من Figma
abstract final class OrderFieldMetrics {
  static const double designHeight = 57.85;
  static const double designRadius = 21.94;
  static const double designPaddingH = 18.95;
  static const double designPaddingV = 16.96;
  static const double designIconGap = 3.99;
  static const double designContentShift = 10;
  static const double designBorderWidth = 1;

  static double get height => designHeight.h;
  static double get radius => designRadius.r;
  static double get iconGap => designIconGap.w;
  static double get contentShift => designContentShift.w;

  /// padding أفقي فقط — المحاذاة العمودية عبر Row.center
  static EdgeInsetsDirectional get horizontalPadding =>
      EdgeInsetsDirectional.fromSTEB(
        designPaddingH.w,
        0,
        designPaddingH.w + contentShift,
        0,
      );

  static Color borderColor({required bool hasError}) => hasError
      ? AppColors.error
      : const Color(0xFF3A3F41).withValues(alpha: 0.26);

  static double borderWidthFor({required bool hasError}) =>
      hasError ? 1 : designBorderWidth;

  static bool hasError(String? errorText) => (errorText ?? '').isNotEmpty;
}
