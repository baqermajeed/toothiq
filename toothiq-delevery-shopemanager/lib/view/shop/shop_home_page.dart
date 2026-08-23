import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controller/main_tab_controller.dart';
import '../../controller/shop_catalog_controller.dart';
import '../../controller/shop_orders_controller.dart';
import '../../controller/shop_products_controller.dart';
import '../../controller/shop_profile_controller.dart';
import '../../model/partner_order.dart';
import '../../utils/app_colors.dart';
import '../../widget/my_text.dart';
import '../../widget/order_card.dart';
import '../../widget/shop/shop_gradient_header.dart';
import 'edit_shop_profile_page.dart';
import 'product_form_page.dart';
import 'shop_brands_page.dart';
import 'shop_categories_page.dart';
import 'shop_order_detail_page.dart';

class ShopHomePage extends StatelessWidget {
  const ShopHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = Get.find<ShopOrdersController>();
    final products = Get.find<ShopProductsController>();
    final catalog = Get.find<ShopCatalogController>();
    final profile = Get.find<ShopProfileController>();
    final tabs = Get.find<MainTabController>(tag: 'shop');

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Obx(() {
        final recent = orders.orders
            .where((o) => o.status != PartnerOrderStatus.canceled)
            .take(5)
            .toList();
        final shop = profile.profile.value;

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: ShopGradientHeader(
                compact: true,
                onEditTap: () => Get.to(() => const EditShopProfilePage()),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 24.h),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Row(
                    children: [
                      Expanded(child: MyText('نظرة عامة', fontSize: 17.sp)),
                      if (shop != null && shop.completionPercent < 100)
                        GestureDetector(
                          onTap: () => Get.to(() => const EditShopProfilePage()),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit_note, size: 14.sp, color: AppColors.warning),
                                SizedBox(width: 4.w),
                                MyText(
                                  'أكمل ملفك',
                                  fontSize: 10.sp,
                                  color: AppColors.warning,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 14.h),
                  Row(
                    children: [
                      Expanded(
                        child: _DashboardStat(
                          icon: Icons.receipt_long_outlined,
                          title: 'طلبات جديدة',
                          value: '${orders.pendingCount}',
                          gradient: const [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
                          iconColor: AppColors.orderStatusPendingText,
                          pulseWarning: orders.pendingCount > 0,
                          onTap: () => tabs.changeTab(1),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _DashboardStat(
                          icon: Icons.kitchen_outlined,
                          title: 'قيد التحضير',
                          value: '${orders.preparingCount}',
                          gradient: const [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
                          iconColor: AppColors.orderStatusAcceptedText,
                          onTap: () => tabs.changeTab(1),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Expanded(
                        child: _DashboardStat(
                          icon: Icons.inventory_2_outlined,
                          title: 'المنتجات',
                          value: '${products.products.length}',
                          gradient: const [Color(0xFFE8F6F7), Color(0xFFB2EBF2)],
                          iconColor: AppColors.primary,
                          onTap: () => tabs.changeTab(2),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _DashboardStat(
                          icon: Icons.category_outlined,
                          title: 'الأقسام',
                          value: '${catalog.shopCategories.length}',
                          gradient: const [Color(0xFFF3E5F5), Color(0xFFE1BEE7)],
                          iconColor: const Color(0xFF7B1FA2),
                          onTap: () => Get.to(() => const ShopCategoriesPage()),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),
                  MyText('إدارة سريعة', fontSize: 16.sp),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.add_box_outlined,
                          label: 'منتج جديد',
                          color: AppColors.primary,
                          onTap: () => Get.to(() => const ProductFormPage()),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.category_outlined,
                          label: 'الأقسام',
                          color: const Color(0xFF7B1FA2),
                          onTap: () => Get.to(() => const ShopCategoriesPage()),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.verified_outlined,
                          label: 'البراندات',
                          color: const Color(0xFF1565C0),
                          onTap: () => Get.to(() => const ShopBrandsPage()),
                        ),
                      ),
                    ],
                  ),
                  if (shop != null && shop.description.isNotEmpty) ...[
                    SizedBox(height: 24.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18.r),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.store_outlined, color: AppColors.primary, size: 20.sp),
                              SizedBox(width: 8.w),
                              MyText('عن المتجر', fontSize: 14.sp),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          MyText(
                            shop.description,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: 24.h),
                  Row(
                    children: [
                      Expanded(child: MyText('آخر الطلبات', fontSize: 16.sp)),
                      TextButton(
                        onPressed: () => tabs.changeTab(1),
                        child: MyText('عرض الكل', fontSize: 12.sp, color: AppColors.primary),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  if (recent.isEmpty)
                    Container(
                      height: 120.h,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: MyText(
                        'لا توجد طلبات بعد',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    )
                  else
                    ...recent.map(
                      (order) => Padding(
                        padding: EdgeInsets.only(bottom: 10.h),
                        child: OrderCard(
                          order: order,
                          onTap: () => Get.to(() => ShopOrderDetailPage(order: order)),
                        ),
                      ),
                    ),
                ]),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _DashboardStat extends StatefulWidget {
  const _DashboardStat({
    required this.icon,
    required this.title,
    required this.value,
    required this.gradient,
    required this.iconColor,
    this.pulseWarning = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final List<Color> gradient;
  final Color iconColor;
  final bool pulseWarning;
  final VoidCallback? onTap;

  @override
  State<_DashboardStat> createState() => _DashboardStatState();
}

class _DashboardStatState extends State<_DashboardStat>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _curve;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _curve = CurvedAnimation(parent: _pulse, curve: Curves.easeInOut);
    if (widget.pulseWarning) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _DashboardStat oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulseWarning && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!widget.pulseWarning && _pulse.isAnimating) {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.pulseWarning) {
      return _buildCard(0);
    }

    return AnimatedBuilder(
      animation: _curve,
      builder: (context, _) => _buildCard(_curve.value),
    );
  }

  Widget _buildCard(double t) {
    final warning = widget.pulseWarning;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: warning
            ? [
                BoxShadow(
                  color: AppColors.warning.withValues(alpha: 0.28 + 0.48 * t),
                  blurRadius: 10 + 20 * t,
                  spreadRadius: 0.5 + 3.8 * t,
                ),
                BoxShadow(
                  color: widget.iconColor.withValues(alpha: 0.18 + 0.35 * t),
                  blurRadius: 6 + 10 * t,
                ),
              ]
            : [
                BoxShadow(
                  color: widget.iconColor.withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(18.r),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: widget.gradient,
              ),
              borderRadius: BorderRadius.circular(18.r),
              border: warning
                  ? Border.all(
                      color: AppColors.warning.withValues(alpha: 0.4 + 0.55 * t),
                      width: 1.5 + t,
                    )
                  : null,
            ),
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      widget.icon,
                      color: widget.iconColor,
                      size: 22.sp,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  MyText(
                    widget.value,
                    fontSize: 24.sp,
                    color: widget.iconColor,
                  ),
                  SizedBox(height: 2.h),
                  MyText(
                    widget.title,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: widget.iconColor.withValues(alpha: 0.85),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22.sp),
              ),
              SizedBox(height: 8.h),
              MyText(label, fontSize: 11.sp, fontWeight: FontWeight.w600),
            ],
          ),
        ),
      ),
    );
  }
}
