import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../utils/app_colors.dart';
import '../app_back_button.dart';
import '../my_text.dart';

class SectionAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const SectionAppBar({super.key, required this.title});

  @override
  Size get preferredSize => Size.fromHeight(56.h);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      title: MyText(
        title,
        fontSize: 18.sp,
        fontWeight: FontWeight.w800,
        color: AppColors.productTitle,
      ),
      actions: [
        const AppBackButton(),
        SizedBox(width: 8.w),
      ],
    );
  }
}
