import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../utils/app_colors.dart';
import '../app_back_button.dart';
import '../my_text.dart';

class BasketAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showClearButton;
  final VoidCallback? onClearTap;

  const BasketAppBar({
    super.key,
    this.title = 'السلة',
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
        title,
        fontSize: 18.sp,
        fontWeight: FontWeight.w800,
        color: AppColors.productTitle,
      ),
      actions: [
        const AppBackButton(),
        SizedBox(width: 8.w),
      ],
      leading: showClearButton
          ? Padding(
              padding: EdgeInsets.all(8.w),
              child: Material(
                color: const Color(0xFFFFE8E8),
                borderRadius: BorderRadius.circular(12.r),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onClearTap,
                  child: SizedBox(
                    width: 40.w,
                    height: 40.w,
                    child: Center(
                      child: Image.asset(
                        'assets/images/cart/del.png',
                        width: 20.w,
                        height: 20.w,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
