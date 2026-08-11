import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../utils/app_colors.dart';
import '../my_text.dart';

class InfoPageHero extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;

  const InfoPageHero({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.gradientColors = const [
      Color(0xFFE8F6F7),
      Color(0xFFF7FBFC),
      Colors.white,
    ],
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(20.w, 28.h, 20.w, 32.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: gradientColors,
            ),
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(32.r),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  width: 72.w,
                  height: 72.w,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.productStore.withValues(alpha: 0.18),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    size: 34.sp,
                    color: AppColors.productStore,
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              MyText(
                title,
                fontSize: 26.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.productTitle,
                textAlign: TextAlign.right,
                height: 1.35,
              ),
              SizedBox(height: 10.h),
              MyText(
                subtitle,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
                textAlign: TextAlign.right,
                height: 1.65,
              ),
            ],
          ),
        ),
        Positioned(
          top: -18.h,
          left: -24.w,
          child: _DecorCircle(
            size: 110.w,
            color: AppColors.productStore.withValues(alpha: 0.06),
          ),
        ),
        Positioned(
          bottom: 12.h,
          left: 28.w,
          child: _DecorCircle(
            size: 56.w,
            color: AppColors.settingsIcon.withValues(alpha: 0.12),
          ),
        ),
      ],
    );
  }
}

class InfoSectionTitle extends StatelessWidget {
  final String title;
  final String? badge;

  const InfoSectionTitle({super.key, required this.title, this.badge});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (badge != null) ...[
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: MyText(
              badge!,
              fontSize: 11.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.productStore,
            ),
          ),
          SizedBox(width: 10.w),
        ],
        Expanded(
          child: MyText(
            title,
            fontSize: 18.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.productTitle,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class InfoGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const InfoGlassCard({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: AppColors.settingsCardBorder),
        boxShadow: const [
          BoxShadow(
            color: AppColors.orderCardShadow,
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class InfoValueTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const InfoValueTile({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46.w,
          height: 46.w,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                AppColors.productStore.withValues(alpha: 0.14),
                AppColors.primaryLight,
              ],
            ),
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Icon(icon, color: AppColors.productStore, size: 22.sp),
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MyText(
                title,
                fontSize: 15.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.productTitle,
                textAlign: TextAlign.right,
              ),
              SizedBox(height: 6.h),
              MyText(
                description,
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
                textAlign: TextAlign.right,
                height: 1.55,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class InfoStatChip extends StatelessWidget {
  final String value;
  final String label;

  const InfoStatChip({super.key, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: AppColors.orderDetailCardBorder),
        ),
        child: Column(
          children: [
            MyText(
              value,
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.productStore,
            ),
            SizedBox(height: 4.h),
            MyText(
              label,
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}

class InfoContactTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String value;
  final VoidCallback? onTap;

  const InfoContactTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20.r),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: AppColors.settingsCardBorder),
          ),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Container(
                  width: 50.w,
                  height: 50.w,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Icon(icon, color: iconColor, size: 24.sp),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      MyText(
                        title,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        textAlign: TextAlign.right,
                      ),
                      SizedBox(height: 4.h),
                      MyText(
                        value,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.productTitle,
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.north_west_rounded,
                  size: 18.sp,
                  color: AppColors.textLight,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class InfoFaqTile extends StatelessWidget {
  final String question;
  final String answer;

  const InfoFaqTile({
    super.key,
    required this.question,
    required this.answer,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: AppColors.settingsCardBorder),
          boxShadow: const [
            BoxShadow(
              color: AppColors.orderCardShadow,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ExpansionTile(
          tilePadding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 4.h),
          childrenPadding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
          iconColor: AppColors.productStore,
          collapsedIconColor: AppColors.textSecondary,
          title: MyText(
            question,
            fontSize: 14.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.productTitle,
            textAlign: TextAlign.right,
          ),
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: MyText(
                answer,
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
                textAlign: TextAlign.right,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DecorCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _DecorCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
