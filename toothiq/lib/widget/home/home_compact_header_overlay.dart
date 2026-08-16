import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../view/notifications/notifications_page.dart';
import '../../view/search/search_page.dart';
import '../main_app_bar.dart';
import '../pinned_blur_gradient_background.dart';
import '../search_filter_row.dart';
import 'home_scroll_metrics.dart';

/// هيدر ثابت يظهر بعد اختفاء شعار الرئيسية — شريط بحث + إشعارات
class HomeCompactHeaderOverlay extends StatefulWidget {
  const HomeCompactHeaderOverlay({
    super.key,
    required this.scrollOffsetListenable,
    required this.searchController,
  });

  final ValueListenable<double> scrollOffsetListenable;
  final TextEditingController searchController;

  @override
  State<HomeCompactHeaderOverlay> createState() =>
      _HomeCompactHeaderOverlayState();
}

class _HomeCompactHeaderOverlayState extends State<HomeCompactHeaderOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _appear;
  late final Animation<double> _t;

  @override
  void initState() {
    super.initState();
    _appear = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
      reverseDuration: const Duration(milliseconds: 240),
    );
    _t = CurvedAnimation(
      parent: _appear,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    widget.scrollOffsetListenable.addListener(_syncVisibility);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncVisibility());
  }

  @override
  void didUpdateWidget(HomeCompactHeaderOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollOffsetListenable != widget.scrollOffsetListenable) {
      oldWidget.scrollOffsetListenable.removeListener(_syncVisibility);
      widget.scrollOffsetListenable.addListener(_syncVisibility);
      _syncVisibility();
    }
  }

  @override
  void dispose() {
    widget.scrollOffsetListenable.removeListener(_syncVisibility);
    _appear.dispose();
    super.dispose();
  }

  void _syncVisibility() {
    final hideStart = HomeScrollMetrics.logoHideStartOffset();
    final hideRange = HomeScrollMetrics.logoHideAnimationRange();
    final offset = widget.scrollOffsetListenable.value;
    final shouldShow = offset >= hideStart + hideRange * 0.2;

    if (shouldShow) {
      if (_appear.status != AnimationStatus.forward &&
          _appear.status != AnimationStatus.completed) {
        _appear.forward();
      }
    } else if (_appear.status != AnimationStatus.reverse &&
        _appear.status != AnimationStatus.dismissed) {
      _appear.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return AnimatedBuilder(
      animation: _t,
      builder: (context, child) {
        final t = _t.value;
        if (t <= 0) return const SizedBox.shrink();

        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
            ignoring: t < 0.45,
            child: Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset(0, lerpDouble(-18.h, 0, t)!),
                child: Transform.scale(
                  alignment: Alignment.topCenter,
                  scale: lerpDouble(0.97, 1, t),
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
      child: ClipRect(
        child: Stack(
          children: [
            const Positioned.fill(
              child: IgnorePointer(
                child: PinnedBlurGradientBackground(
                  fadeStops: PinnedBlurHeaderStyle.compactFadeStops,
                  fadeMaskColors: PinnedBlurHeaderStyle.compactFadeMaskColors,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: topInset),
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 36.h),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: EdgeInsetsDirectional.only(start: 20.w),
                        child: SearchFilterRow(
                          controller: widget.searchController,
                          hintText: 'أبحث عن منتج أو متجر محدد ..',
                          readOnly: true,
                          showFilter: false,
                          centerTextVertically: true,
                          height: 42.h,
                          padding: EdgeInsets.zero,
                          onTap: SearchPage.open,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    IconButton(
                      onPressed: NotificationsPage.open,
                      icon: const HeaderNotificationIcon(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
