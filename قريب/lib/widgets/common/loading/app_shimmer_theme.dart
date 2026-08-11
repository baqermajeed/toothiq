import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// ألوان Shimmer موحّدة للتطبيق — تُستورد من مكان واحد لتفادي التكرار.
abstract final class AppShimmerTheme {
  /// لون القاعدة (الخلفية الهادئة للتأثير).
  static const Color baseColor = AppColors.primaryBeige;

  /// لون التمييز (اللمعة المتحركة).
  static const Color highlightColor = AppColors.primaryLight;
}
