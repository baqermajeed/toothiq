import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../controllers/cart_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/cart_item.dart';
import '../common/app_button.dart';
import '../common/app_spacing.dart';
import '../order_notes/order_notes_sheet.dart';
import 'cart_item_tile.dart';

/// واجهة السلة الجانبية — تظهر كشريط جانبي صغير، النقر عليه يفتح/يغلق دون التأثير على التصفح.
class CartBottomSheet {
  CartBottomSheet._();

  static OverlayEntry? _overlayEntry;

  /// يعرض السلة جانبياً (شريط صغير). النقر على الشريط يفتح/يغلق اللوحة.
  static void show() {
    if (_overlayEntry != null) return;
    final overlayContext = Get.overlayContext;
    if (overlayContext == null) return;
    _overlayEntry = OverlayEntry(
      builder: (context) => _SideCartOverlay(
        onRemove: () {
          _overlayEntry?.remove();
          _overlayEntry = null;
        },
      ),
    );
    Overlay.of(overlayContext).insert(_overlayEntry!);
  }

  static void _close() {
    try {
      Get.find<CartController>().isCartPanelExpanded.value = false;
    } catch (_) {}
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}

/// لوحة السلة الجانبية — StatelessWidget، حالة الفتح/الإغلاق في [CartController].
class _SideCartOverlay extends StatelessWidget {
  const _SideCartOverlay({required this.onRemove});

  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final cart = Get.find<CartController>();
    return Obx(() {
      if (cart.items.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) => onRemove());
        return const SizedBox.shrink();
      }
      final size = MediaQuery.sizeOf(context);
      final tabWidth = 48.w;
      final tabHeight = 64.h;
      final panelWidth = (size.width * 0.78).clamp(240.w, 320.w);
      final expanded = cart.isCartPanelExpanded.value;

      final panelHeight = size.height * 0.5;
      final topOffset = (size.height - panelHeight) / 2;

      return Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            child: const SizedBox.expand(),
          ),
          if (expanded)
            Positioned(
              right: 0,
              top: topOffset,
              width: panelWidth + tabWidth,
              height: panelHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _CartPanelContent(
                      panelWidth: panelWidth,
                      panelHeight: panelHeight,
                      onComplete: () {
                        cart.toggleCartPanel();
                        showOrderNotesSheet(
                          onOrderSuccess: () {
                            CartBottomSheet._close();
                            Get.toNamed('/cart');
                          },
                        );
                      },
                      onEmpty: CartBottomSheet._close,
                    ),
                  ),
                  _CartTabStrip(onTap: cart.toggleCartPanel, isExpanded: true),
                ],
              ),
            )
          else
            _buildDraggableFloatingStrip(
              size: size,
              tabWidth: tabWidth,
              tabHeight: tabHeight,
              cart: cart,
            ),
        ],
      );
    });
  }
}

/// يبني زر السلة العائم (مطوي) مع دعم السحب وتحديث الموضع.
Widget _buildDraggableFloatingStrip({
  required Size size,
  required double tabWidth,
  required double tabHeight,
  required CartController cart,
}) {
  return Obx(() {
    final pos = cart.floatingCartPosition.value;
    final left = pos?.dx;
    final top = pos?.dy ?? (size.height - tabHeight) / 2;
    final useRight = left == null;
    return Positioned(
      left: useRight ? null : left,
      right: useRight ? 0 : null,
      top: top,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanStart: (_) => cart.startFloatingCartDrag(size.width, size.height, tabWidth, tabHeight),
        onPanUpdate: (details) => cart.applyFloatingCartDrag(details.delta, size.width, size.height, tabWidth, tabHeight),
        onPanEnd: (_) {
          if (!cart.floatingCartIsDragging.value) cart.toggleCartPanel();
          cart.endFloatingCartDrag();
        },
        child: _CartTabStrip(onTap: cart.toggleCartPanel, isExpanded: false),
      ),
    );
  });
}

/// شريط جانبي صغير — أيقونة السلة + العدد. النقر يفتح/يغلق اللوحة.
class _CartTabStrip extends StatelessWidget {
  const _CartTabStrip({required this.onTap, required this.isExpanded});

  final VoidCallback onTap;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final cart = Get.find<CartController>();
    return Obx(() {
      if (cart.items.isEmpty) return const SizedBox.shrink();
      final count = cart.itemCount;
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18.r),
            bottomLeft: Radius.circular(18.r),
          ),
          child: Container(
            padding: EdgeInsets.all(17.w),
           
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.circular(10.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDark.withValues(alpha: 0.35),
                  blurRadius: 12.r,
                  offset: Offset(-3.w, 0),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    SvgPicture.asset(
                      'assets/icons/dark-shop-cart-svgrepo-com.svg',
                      width: 24.sp,
                      height: 24.sp,
                      colorFilter: ColorFilter.mode(AppColors.primaryLight, BlendMode.srcIn),
                    ),
                    if (count > 0)
                      Positioned(
                        right: -6.w,
                        top: -6.h,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(12.r),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryDark.withValues(alpha: 0.2),
                                blurRadius: 4.r,
                              ),
                            ],
                          ),
                          constraints: BoxConstraints(minWidth: 20.w, minHeight: 20.h),
                          child: Center(
                            child: Text(
                              count > 99 ? '99+' : '$count',
                              style: TextStyle(
                                fontFamily: kFontFamilyCairo,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                if (isExpanded) ...[
                  SizedBox(height: 6.h),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20.sp,
                    color: AppColors.primaryLight.withValues(alpha: 0.95),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _CartPanelContent extends StatelessWidget {
  const _CartPanelContent({
    required this.panelWidth,
    required this.panelHeight,
    required this.onComplete,
    required this.onEmpty,
  });

  final double panelWidth;
  final double panelHeight;
  final VoidCallback onComplete;
  final VoidCallback onEmpty;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 12,
      shadowColor: AppColors.primaryDark.withValues(alpha: 0.28),
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(22.r),
        bottomLeft: Radius.circular(22.r),
      ),
      child: Container(
        width: panelWidth,
        constraints: BoxConstraints(maxHeight: panelHeight),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(22.r),
            bottomLeft: Radius.circular(22.r),
          ),
          border: Border.all(
            color: AppColors.primaryDark.withValues(alpha: 0.4),
            width: 2.w,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
              child: Row(
                children: [
                  Text(
                    'السلة',
                    style: TextStyle(
                      fontFamily: kFontFamilyCairo,
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1.h, color: AppColors.border.withValues(alpha: 0.6)),
            Flexible(
              child: Obx(() {
                final cart = Get.find<CartController>();
                if (cart.items.isEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) => onEmpty());
                  return _EmptyCartInSheet();
                }
                return _CartListAndFooter(
                  cart: cart,
                  onComplete: onComplete,
                  onRemoveLast: onEmpty,
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}


class _EmptyCartInSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 48.sp,
            color: AppColors.primaryMedium.withValues(alpha: 0.5),
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            'السلة فارغة',
            style: TextStyle(
              fontFamily: kFontFamilyCairo,
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CartListAndFooter extends StatelessWidget {
  const _CartListAndFooter({
    required this.cart,
    required this.onComplete,
    required this.onRemoveLast,
  });

  final CartController cart;
  final VoidCallback onComplete;
  final VoidCallback onRemoveLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: ListView.separated(
            padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
            physics: const BouncingScrollPhysics(),
            shrinkWrap: true,
            itemCount: cart.items.length,
            separatorBuilder: (_, __) => SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final CartItem item = cart.items[index];
              return CartItemTile(
                item: item,
                compact: true,
                onQuantityChanged: (qty) => cart.updateQuantity(index, qty),
                onRemove: () {
                  cart.removeAt(index);
                  if (cart.items.isEmpty) onRemoveLast();
                },
                formatPrice: formatCartPrice,
              );
            },
          ),
        ),
        CartTotalBar(total: cart.totalPrice, formatPrice: formatCartPrice),
        Padding(
          padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md + 12.h),
          child: SafeArea(
            top: false,
            child: AppButton(
              label: 'إتمام الطلب',
              onPressed: onComplete,
            ),
          ),
        ),
      ],
    );
  }
}
