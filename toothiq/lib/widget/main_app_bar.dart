import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../utils/app_colors.dart';
import '../view/basket/basket_page.dart';
import '../view/notifications/notifications_page.dart';
import '../service_layer/services/notification_inbox_service.dart';
import 'cart/cart_icon.dart';
import 'home/home_scroll_metrics.dart';
import 'my_text.dart';
import 'pinned_blur_gradient_background.dart';

/// هيدر زجاجي ضبابي للصفحات الرئيسية
class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBrandLogo;

  static const brandLogoAsset = 'assets/images/icon/toothiqtext.png';
  /// عند عدم وجود إشعار جديد / الكل مقروء
  static const notificationIconAsset = 'assets/images/icon/noti11.png';
  /// عند وجود إشعار جديد أو غير مقروء
  static const notificationNewIconAsset = 'assets/images/icon/noti22.png';

  static double toolbarHeight() => 56.h;
  static double iconSize() => 29.w;
  static double brandLogoHeight() => 18.h;

  const MainAppBar({
    super.key,
    required this.title,
    this.showBrandLogo = false,
  });

  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight());

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      flexibleSpace: const ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: IgnorePointer(child: PinnedBlurGradientBackground()),
            ),
          ],
        ),
      ),
      title: showBrandLogo
          ? Image.asset(
              brandLogoAsset,
              height: brandLogoHeight(),
              fit: BoxFit.contain,
            )
          : MyText(
              title,
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
      leading: IconButton(
        onPressed: () => BasketPage.open(),
        icon: CartHeaderIcon(size: MainAppBar.iconSize()),
      ),
      actions: [
        IconButton(
          onPressed: NotificationsPage.open,
          icon: const HeaderNotificationIcon(),
        ),
        SizedBox(width: 4.w),
      ],
    );
  }
}

/// أيقونة الإشعارات مع تبديل الأصل عند وجود غير مقروء
class HeaderNotificationIcon extends StatelessWidget {
  const HeaderNotificationIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final hasNotification = Get.isRegistered<NotificationInboxService>()
          ? Get.find<NotificationInboxService>().hasUnread.value
          : false;

      return Image.asset(
        hasNotification
            ? MainAppBar.notificationNewIconAsset
            : MainAppBar.notificationIconAsset,
        width: MainAppBar.iconSize(),
        height: MainAppBar.iconSize(),
        fit: BoxFit.contain,
      );
    });
  }
}

/// هيدر زجاجي عائم يختفي عند التمرير — للصفحة الرئيسية
class MainGlassHeaderOverlay extends StatelessWidget {
  const MainGlassHeaderOverlay({
    super.key,
    required this.scrollOffsetListenable,
    this.showBrandLogo = true,
    this.title = 'ToothIQ',
  });

  final ValueListenable<double> scrollOffsetListenable;
  final bool showBrandLogo;
  final String title;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final barHeight = topInset + MainAppBar.toolbarHeight();
    final hideStart = HomeScrollMetrics.logoHideStartOffset();
    final hideRange = HomeScrollMetrics.logoHideAnimationRange();

    return ValueListenableBuilder<double>(
      valueListenable: scrollOffsetListenable,
      builder: (context, scrollOffset, _) {
        final hideProgress =
            ((scrollOffset - hideStart) / hideRange).clamp(0.0, 1.0);
        final opacity = 1.0 - hideProgress;

        if (opacity <= 0) return const SizedBox.shrink();

        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: barHeight + 24.h,
          child: IgnorePointer(
            ignoring: opacity < 0.1,
            child: Opacity(
              opacity: opacity,
              child: Transform.translate(
                offset: Offset(0, -12.h * hideProgress),
                child: ClipRect(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const Positioned.fill(
                        child: IgnorePointer(
                          child: PinnedBlurGradientBackground(),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: barHeight,
                        child: Padding(
                          padding: EdgeInsets.only(top: topInset),
                          child: SizedBox(
                            height: MainAppBar.toolbarHeight(),
                            child: NavigationToolbar(
                              middleSpacing: 16,
                              leading: IconButton(
                                onPressed: () => BasketPage.open(),
                                icon: CartHeaderIcon(size: MainAppBar.iconSize()),
                              ),
                              middle: showBrandLogo
                                  ? Image.asset(
                                      MainAppBar.brandLogoAsset,
                                      height: MainAppBar.brandLogoHeight(),
                                      fit: BoxFit.contain,
                                    )
                                  : MyText(
                                      title,
                                      fontSize: 20.sp,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: NotificationsPage.open,
                                    icon: const HeaderNotificationIcon(),
                                  ),
                                  SizedBox(width: 4.w),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
