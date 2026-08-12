import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

/// زر الرجوع الموحّد في كل التطبيق — يستخدم `backicon.png`.
class AppBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final double size;

  const AppBackButton({
    super.key,
    this.onPressed,
    this.size = 34,
  });

  static const assetPath = 'assets/images/icon/backicon.png';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(6.w),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed ?? Get.back,
          customBorder: const CircleBorder(),
          child: Image.asset(
            assetPath,
            width: size.w,
            height: size.w,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
