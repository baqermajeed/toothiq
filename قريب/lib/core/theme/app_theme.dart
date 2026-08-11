import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

/// اسم عائلة خط التطبيق (Cairo).
const String kFontFamilyCairo = 'Cairo';

/// اسم عائلة خط العلامة (قريب) — Kufam.
const String kFontFamilyKufam = 'Kufam';

/// ثيم التطبيق العصري باستخدام ألوان qaryp وخط Cairo.
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      fontFamily: kFontFamilyCairo,
      textTheme: _buildTextTheme(),
      colorScheme: ColorScheme.light(
        primary: AppColors.primaryDark,
        onPrimary: AppColors.primaryLight,
        secondary: AppColors.primaryMedium,
        onSecondary: AppColors.primaryLight,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.surface,
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          fontFamily: kFontFamilyCairo,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primaryDark, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        hintStyle: TextStyle(
          color: AppColors.textSecondary,
          fontFamily: kFontFamilyCairo,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: AppColors.primaryLight,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
        ),
      ),
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      fontFamily: kFontFamilyCairo,
      textTheme: _buildTextTheme(),
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primaryLight,
        onPrimary: AppColors.primaryDark,
        secondary: AppColors.primaryBeige,
        onSecondary: AppColors.primaryDark,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.textPrimaryDark,
        error: AppColors.error,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.surfaceDark,
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.textPrimaryDark,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          fontFamily: kFontFamilyCairo,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryDark,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.borderDark,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        hintStyle: TextStyle(
          color: AppColors.textSecondaryDark,
          fontFamily: kFontFamilyCairo,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.primaryDark,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryDark;
          }
          return AppColors.textSecondaryDark;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryLight.withValues(alpha: 0.6);
          }
          return AppColors.borderDark;
        }),
      ),
    );
  }

  static TextTheme _buildTextTheme() {
    return TextTheme(
      displayLarge: TextStyle(fontFamily: kFontFamilyCairo, fontWeight: FontWeight.w700),
      displayMedium: TextStyle(fontFamily: kFontFamilyCairo, fontWeight: FontWeight.w600),
      displaySmall: TextStyle(fontFamily: kFontFamilyCairo, fontWeight: FontWeight.w600),
      headlineLarge: TextStyle(fontFamily: kFontFamilyCairo, fontWeight: FontWeight.w600),
      headlineMedium: TextStyle(fontFamily: kFontFamilyCairo, fontWeight: FontWeight.w600),
      headlineSmall: TextStyle(fontFamily: kFontFamilyCairo, fontWeight: FontWeight.w500),
      titleLarge: TextStyle(fontFamily: kFontFamilyCairo, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(fontFamily: kFontFamilyCairo, fontWeight: FontWeight.w500),
      titleSmall: TextStyle(fontFamily: kFontFamilyCairo, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(fontFamily: kFontFamilyCairo, fontWeight: FontWeight.w400),
      bodyMedium: TextStyle(fontFamily: kFontFamilyCairo, fontWeight: FontWeight.w400),
      bodySmall: TextStyle(fontFamily: kFontFamilyCairo, fontWeight: FontWeight.w400),
      labelLarge: TextStyle(fontFamily: kFontFamilyCairo, fontWeight: FontWeight.w500),
      labelMedium: TextStyle(fontFamily: kFontFamilyCairo, fontWeight: FontWeight.w500),
      labelSmall: TextStyle(fontFamily: kFontFamilyCairo, fontWeight: FontWeight.w500),
    );
  }
}
