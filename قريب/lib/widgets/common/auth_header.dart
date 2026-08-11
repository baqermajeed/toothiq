import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'app_spacing.dart';

/// رأس شاشات المصادقة: اسم التطبيق "قريب" بخط Kufam كبير والعبارة التحتية بخط Cairo صغير.
class AuthHeader extends StatelessWidget {
  const AuthHeader({
    super.key,
    this.logoAssetPath = 'assets/icon_app.png',
  });

  final String logoAssetPath;

  static const String _appName = 'قريب';
  static const String _tagline = 'يخليك دائما قريب على المحلات';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: Image.asset(
            logoAssetPath,
            height: 140.h,
            width: 140.w,
            fit: BoxFit.contain,
          ),
        ),
        AppSpacing.verticalMd,
        Text(
          _appName,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: kFontFamilyKufam,
            fontSize: 42.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDark,
          ),
        ),
        AppSpacing.verticalSm,
        Text(
          _tagline,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: kFontFamilyCairo,
            fontSize: 15.sp,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
