import 'package:flutter/material.dart';

/// ألوان التطبيق الأساسية وفق التدرج المطلوب.
abstract final class AppColors {
  /// #574A24 — بني غامق (أساسي)
  static const Color primaryDark = Color(0xFF574A24);

  /// #80775C — بني متوسط
  static const Color primaryMedium = Color(0xFF80775C);

  /// #FAE8B4 — كريم فاتح
  static const Color primaryLight = Color(0xFFFAE8B4);

  /// #CBBD93 — بيج
  static const Color primaryBeige = Color(0xFFCBBD93);

  /// للخلفيات الفاتحة والنصوص على الألوان الداكنة
  static const Color surface = Color(0xFFFFFBF5);

  /// للنصوص الأساسية
  static const Color textPrimary = Color(0xFF574A24);

  /// للنصوص الثانوية
  static const Color textSecondary = Color(0xFF80775C);

  /// للحدود والحواجز
  static const Color border = Color(0xFFCBBD93);

  /// للخطأ
  static const Color error = Color(0xFFB00020);

  // ——— الوضع الليلي ———
  static const Color surfaceDark = Color(0xFF1C1914);
  static const Color textPrimaryDark = Color(0xFFFAE8B4);
  static const Color textSecondaryDark = Color(0xFFCBBD93);
  static const Color borderDark = Color(0xFF3D3629);
}
