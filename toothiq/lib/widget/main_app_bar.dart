import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controller/home_controller.dart';
import '../utils/app_colors.dart';
import '../view/basket/basket_page.dart';
import '../view/notifications/notifications_page.dart';
import 'cart/cart_icon.dart';
import 'my_text.dart';

class MainAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final ScrollController? scrollController;
  final bool showBrandLogo;

  static const brandLogoAsset = 'assets/images/icon/toothiqtext.png';
  static const notificationIconAsset = 'assets/images/icon/Frame 427321658.png';
  static const notificationNewIconAsset =
      'assets/images/icon/Frame 427321659.png';

  const MainAppBar({
    super.key,
    required this.title,
    this.scrollController,
    this.showBrandLogo = false,
  });

  @override
  Size get preferredSize => Size.fromHeight(56.h);

  @override
  State<MainAppBar> createState() => _MainAppBarState();
}

class _MainAppBarState extends State<MainAppBar> {
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    widget.scrollController?.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateScrollState());
  }

  @override
  void didUpdateWidget(MainAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController?.removeListener(_onScroll);
      widget.scrollController?.addListener(_onScroll);
      _updateScrollState();
    }
  }

  @override
  void dispose() {
    widget.scrollController?.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() => _updateScrollState();

  void _updateScrollState() {
    final controller = widget.scrollController;
    var scrolled = false;
    if (controller != null && controller.positions.length == 1) {
      scrolled = controller.positions.first.pixels > 0;
    }
    if (scrolled == _isScrolled) return;
    if (mounted) setState(() => _isScrolled = scrolled);
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: _isScrolled ? 2 : 0,
      scrolledUnderElevation: 0,
      shadowColor: AppColors.shadow,
      centerTitle: true,
      title: widget.showBrandLogo
          ? Image.asset(
              MainAppBar.brandLogoAsset,
              height: 22.h,
              fit: BoxFit.contain,
            )
          : MyText(
              widget.title,
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
      leading: IconButton(
        onPressed: () => BasketPage.open(),
        icon: CartHeaderIcon(size: 32.w),
      ),
      actions: [
        Obx(
          () {
            final hasNotification = Get.isRegistered<HomeController>()
                ? Get.find<HomeController>().hasNotification.value
                : false;

            return IconButton(
              onPressed: () {
                if (Get.isRegistered<HomeController>()) {
                  Get.find<HomeController>().hasNotification.value = false;
                }
                NotificationsPage.open();
              },
              icon: Image.asset(
                hasNotification
                    ? MainAppBar.notificationNewIconAsset
                    : MainAppBar.notificationIconAsset,
                width: 32.w,
                height: 32.w,
                fit: BoxFit.contain,
              ),
            );
          },
        ),
        SizedBox(width: 4.w),
      ],
    );
  }
}
