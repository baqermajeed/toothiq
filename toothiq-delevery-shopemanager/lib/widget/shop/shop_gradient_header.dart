import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controller/shop_profile_controller.dart';
import '../../utils/app_colors.dart';
import '../my_text.dart';
import 'app_image.dart';

class ShopGradientHeader extends StatelessWidget {
  const ShopGradientHeader({
    super.key,
    this.showCompletion = true,
    this.onEditTap,
    this.compact = false,
  });

  final bool showCompletion;
  final VoidCallback? onEditTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final profileCtrl = Get.find<ShopProfileController>();

    return Obx(() {
      final shop = profileCtrl.profile.value;
      if (shop == null) return const SizedBox.shrink();

      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFF0D3136), Color(0xFF14919B), Color(0xFF1BB5BE)],
          ),
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(compact ? 20.r : 28.r),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.w, compact ? 8.h : 12.h, 20.w, 24.h),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: AppImage(
                        path: shop.logoPath,
                        width: compact ? 64.w : 76.w,
                        height: compact ? 64.w : 76.w,
                        borderRadius: BorderRadius.circular(100),
                        icon: Icons.storefront_rounded,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        iconColor: Colors.white,
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MyText(
                            shop.name,
                            fontSize: compact ? 17.sp : 20.sp,
                            color: Colors.white,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 6.h),
                          if (shop.address.isNotEmpty)
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  color: Colors.white.withValues(alpha: 0.85),
                                  size: 14.sp,
                                ),
                                SizedBox(width: 4.w),
                                Expanded(
                                  child: MyText(
                                    shop.address,
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withValues(alpha: 0.85),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          if (!compact && shop.phonePrimary.isNotEmpty) ...[
                            SizedBox(height: 4.h),
                            Row(
                              children: [
                                Icon(
                                  Icons.phone_outlined,
                                  color: Colors.white.withValues(alpha: 0.85),
                                  size: 14.sp,
                                ),
                                SizedBox(width: 4.w),
                                MyText(
                                  shop.phonePrimary,
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                                if (shop.phoneSecondary?.isNotEmpty == true) ...[
                                  SizedBox(width: 8.w),
                                  MyText(
                                    '· ${shop.phoneSecondary}',
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (onEditTap != null)
                      Material(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12.r),
                        child: InkWell(
                          onTap: onEditTap,
                          borderRadius: BorderRadius.circular(12.r),
                          child: Padding(
                            padding: EdgeInsets.all(10.w),
                            child: Icon(
                              Icons.edit_outlined,
                              color: Colors.white,
                              size: 20.sp,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                if (showCompletion) ...[
                  SizedBox(height: 16.h),
                  _CompletionBar(percent: shop.completionPercent),
                ],
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _CompletionBar extends StatelessWidget {
  const _CompletionBar({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.verified_outlined,
                color: Colors.white.withValues(alpha: 0.9),
                size: 16.sp,
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: MyText(
                  percent >= 100
                      ? 'ملف المتجر مكتمل'
                      : 'أكمل بيانات متجرك لظهور أفضل في ToothIQ',
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.95),
                ),
              ),
              MyText(
                '$percent%',
                fontSize: 12.sp,
                color: Colors.white,
              ),
            ],
          ),
          SizedBox(height: 8.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(6.r),
            child: LinearProgressIndicator(
              value: percent / 100,
              minHeight: 5.h,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
