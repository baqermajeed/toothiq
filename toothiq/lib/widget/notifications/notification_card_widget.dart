import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../model/notification_model.dart';
import '../../utils/app_colors.dart';

/// مقاييس كارد الإشعار — مطابقة لـ Art Inspiration
abstract final class NotificationCardMetrics {
  static const Color pageBackground = Color(0xFFFFFFFF);
  static const Color iconBackground = Color(0x1A022B2F); // #022B2F @ 10%
  static const Color titleColor = Color(0xFF040814);
  static const Color cardShadowColor = Color(0xFF659AB9);
  static const String iconAsset = 'assets/images/icon/Frame 427321749.png';

  static double cardRadius() => 24.r;
  static double cardShadowBlur() => 3.76.r;

  static List<BoxShadow> cardShadow() => [
        BoxShadow(
          color: cardShadowColor.withValues(alpha: 0.38),
          blurRadius: cardShadowBlur(),
          offset: Offset.zero,
          spreadRadius: 0,
        ),
      ];

  static double iconSize() => 34.08.w;
  static double iconAssetSize() => 30.w;
}

class NotificationCardWidget extends StatelessWidget {
  final AppNotificationModel notification;
  final VoidCallback? onTap;

  const NotificationCardWidget({
    super.key,
    required this.notification,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;
    final textColor = isUnread
        ? NotificationCardMetrics.titleColor
        : NotificationCardMetrics.titleColor.withValues(alpha: 0.5);

    final card = Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius:
            BorderRadius.circular(NotificationCardMetrics.cardRadius()),
        boxShadow: NotificationCardMetrics.cardShadow(),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _NotificationIcon(),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  notification.title,
                  style: TextStyle(
                    fontFamily: 'Expo Arabic',
                    fontSize: 13.96.sp,
                    fontWeight: FontWeight.w700,
                    height: 1.5,
                    color: textColor,
                  ),
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Text(
                  notification.description,
                  style: TextStyle(
                    fontFamily: 'Expo Arabic',
                    fontSize: 11.97.sp,
                    fontWeight: FontWeight.w700,
                    height: 1.5,
                    color: textColor,
                  ),
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            notification.timeLabel,
            style: TextStyle(
              fontFamily: 'Expo Arabic',
              fontSize: 11.97.sp,
              fontWeight: FontWeight.w700,
              height: 1.5,
              color: textColor,
            ),
            textAlign: TextAlign.left,
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(NotificationCardMetrics.cardRadius()),
        child: card,
      ),
    );
  }
}

class _NotificationIcon extends StatelessWidget {
  const _NotificationIcon();

  @override
  Widget build(BuildContext context) {
    final size = NotificationCardMetrics.iconSize();
    final assetSize = NotificationCardMetrics.iconAssetSize();

    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: NotificationCardMetrics.iconBackground,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Image.asset(
        NotificationCardMetrics.iconAsset,
        width: assetSize,
        height: assetSize,
        fit: BoxFit.contain,
      ),
    );
  }
}
