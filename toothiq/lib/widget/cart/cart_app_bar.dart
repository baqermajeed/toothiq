import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../utils/app_colors.dart';
import '../app_back_button.dart';
import '../my_text.dart';

class CartAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showClearButton;
  final VoidCallback? onClearTap;

  const CartAppBar({
    super.key,
    this.showClearButton = false,
    this.onClearTap,
  });

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
        'السلة',
        fontSize: 18.sp,
        fontWeight: FontWeight.w800,
        color: AppColors.productTitle,
      ),
      leading: showClearButton
          ? IconButton(
              onPressed: onClearTap,
              icon: Icon(
                Icons.delete_outline_rounded,
                color: AppColors.settingsDelete,
                size: 26.sp,
              ),
            )
          : const SizedBox.shrink(),
      actions: [
        const AppBackButton(),
        SizedBox(width: 8.w),
      ],
    );
  }
}
