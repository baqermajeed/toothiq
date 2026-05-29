import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../utils/app_colors.dart';

class AuthFooterLink extends StatelessWidget {
  final String prefix;
  final String linkText;
  final VoidCallback onLinkTap;

  const AuthFooterLink({
    super.key,
    required this.prefix,
    required this.linkText,
    required this.onLinkTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: TextStyle(
            fontFamily: 'Expo Arabic',
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          children: [
            TextSpan(text: prefix),
            TextSpan(
              text: linkText,
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.primary,
              ),
              recognizer: TapGestureRecognizer()..onTap = onLinkTap,
            ),
          ],
        ),
      ),
    );
  }
}
