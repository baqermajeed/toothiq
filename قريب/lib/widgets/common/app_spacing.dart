import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// مسافات متجاوبة للاستخدام المشترك.
abstract final class AppSpacing {
  static double get xs => 4.w;
  static double get sm => 8.w;
  static double get md => 16.w;
  static double get lg => 24.w;
  static double get xl => 32.w;
  static double get xxl => 48.w;

  static SizedBox get verticalXs => SizedBox(height: 4.h);
  static SizedBox get verticalSm => SizedBox(height: 8.h);
  static SizedBox get verticalMd => SizedBox(height: 16.h);
  static SizedBox get verticalLg => SizedBox(height: 24.h);
  static SizedBox get verticalXl => SizedBox(height: 32.h);
  static SizedBox get verticalXxl => SizedBox(height: 48.h);

  static SizedBox get horizontalXs => SizedBox(width: 4.w);
  static SizedBox get horizontalSm => SizedBox(width: 8.w);
  static SizedBox get horizontalMd => SizedBox(width: 16.w);
  static SizedBox get horizontalLg => SizedBox(width: 24.w);
}
