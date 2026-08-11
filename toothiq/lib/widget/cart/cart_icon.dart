import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controller/cart_controller.dart';
import '../../utils/app_colors.dart';

class CartIcon extends StatelessWidget {
  const CartIcon({
    super.key,
    this.size,
    this.color,
  });

  final double? size;
  final Color? color;

  static const assetPath = 'assets/images/icon/basket23.png';

  @override
  Widget build(BuildContext context) {
    final dimension = size ?? 26.w;
    final image = Image.asset(
      assetPath,
      width: dimension,
      height: dimension,
      fit: BoxFit.contain,
    );

    if (color == null) return image;

    return ColorFiltered(
      colorFilter: ColorFilter.mode(color!, BlendMode.srcIn),
      child: image,
    );
  }
}

/// أيقونة السلة في الهيدر مع شارة حمراء وأنيميشن عند الإضافة.
class CartHeaderIcon extends StatefulWidget {
  const CartHeaderIcon({super.key, this.size});

  final double? size;
  static const headerAssetPath = 'assets/images/icon/Frame 427321660.png';

  @override
  State<CartHeaderIcon> createState() => _CartHeaderIconState();
}

class _CartHeaderIconState extends State<CartHeaderIcon>
    with TickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final Animation<double> _bounceScale;
  late final AnimationController _badgePulseController;
  late final Animation<double> _badgePulse;
  Worker? _cartWorker;
  int _previousCount = 0;

  CartController? get _cart =>
      Get.isRegistered<CartController>() ? Get.find<CartController>() : null;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _bounceScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.16), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.16, end: 0.96), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.96, end: 1.0), weight: 40),
    ]).animate(CurvedAnimation(parent: _bounceController, curve: Curves.easeOut));

    _badgePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _badgePulse = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(parent: _badgePulseController, curve: Curves.easeInOut),
    );

    final cart = _cart;
    if (cart != null) {
      _previousCount = cart.itemCount;
      _syncBadgePulse(cart.itemCount);
      _cartWorker = ever(cart.items, (_) {
        _onCartChanged(cart.itemCount);
      });
    }
  }

  void _onCartChanged(int count) {
    if (count > _previousCount) {
      _bounceController.forward(from: 0);
    }
    _previousCount = count;
    _syncBadgePulse(count);
  }

  void _syncBadgePulse(int count) {
    if (count > 0) {
      if (!_badgePulseController.isAnimating) {
        _badgePulseController.repeat(reverse: true);
      }
      return;
    }
    _badgePulseController
      ..stop()
      ..reset();
  }

  @override
  void dispose() {
    _cartWorker?.dispose();
    _bounceController.dispose();
    _badgePulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = _cart;
    final iconSize = widget.size ?? 28.sp;

    if (cart == null) {
      return Image.asset(
        CartHeaderIcon.headerAssetPath,
        width: iconSize,
        height: iconSize,
        fit: BoxFit.contain,
      );
    }

    return Obx(() {
      final count = cart.itemCount;
      final hasItems = count > 0;

      return ScaleTransition(
        scale: _bounceScale,
        child: SizedBox(
          width: iconSize,
          height: iconSize,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Image.asset(
                CartHeaderIcon.headerAssetPath,
                width: iconSize,
                height: iconSize,
                fit: BoxFit.contain,
              ),
              if (hasItems)
                Positioned(
                  top: -1.h,
                  right: -1.w,
                  child: ScaleTransition(
                    scale: _badgePulse,
                    child: Container(
                      width: 9.w,
                      height: 9.w,
                      decoration: BoxDecoration(
                        color: AppColors.favoriteRed,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.4),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.favoriteRed.withValues(alpha: 0.45),
                            blurRadius: 4,
                            spreadRadius: 0.5,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}
