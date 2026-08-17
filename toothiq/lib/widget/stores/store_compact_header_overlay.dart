import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../app_back_button.dart';
import '../pinned_blur_gradient_background.dart';
import '../search_filter_row.dart';
import 'store_scroll_metrics.dart';

/// هيدر ثابت يظهر بعد اختفاء صورة المتجر والتبويبات — بحث + رجوع
class StoreCompactHeaderOverlay extends StatefulWidget {
  const StoreCompactHeaderOverlay({
    super.key,
    required this.scrollOffsetListenable,
    required this.searchController,
    required this.hideStartOffset,
  });

  final ValueListenable<double> scrollOffsetListenable;
  final TextEditingController searchController;
  final double hideStartOffset;

  @override
  State<StoreCompactHeaderOverlay> createState() =>
      _StoreCompactHeaderOverlayState();
}

class _StoreCompactHeaderOverlayState extends State<StoreCompactHeaderOverlay>
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
  void didUpdateWidget(StoreCompactHeaderOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollOffsetListenable != widget.scrollOffsetListenable ||
        oldWidget.hideStartOffset != widget.hideStartOffset) {
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
    final hideRange = StoreScrollMetrics.hideAnimationRange();
    final offset = widget.scrollOffsetListenable.value;
    final shouldShow = offset >= widget.hideStartOffset + hideRange * 0.2;

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
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
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
                            hintText: 'ابحث عن منتج',
                            showFilter: false,
                            centerTextVertically: true,
                            height: 42.h,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      const AppBackButton(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
