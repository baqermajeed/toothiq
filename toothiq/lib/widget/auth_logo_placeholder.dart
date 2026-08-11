import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AuthLogoPlaceholder extends StatelessWidget {
  final double size;

  static const assetPath = 'assets/images/icon/toothiqlogo.png';

  const AuthLogoPlaceholder({super.key, this.size = 140});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size.w,
      height: size.w,
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
      ),
    );
  }
}
