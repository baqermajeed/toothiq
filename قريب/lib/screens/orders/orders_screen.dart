import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/orders_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/order.dart';
import '../../utils/price_formatter.dart';
import '../../widgets/common/app_spacing.dart';
import '../../widgets/orders/order_note_audio_player.dart';
import '../../widgets/orders/order_status_chip.dart';


/// تنسيق التاريخ للعرض.
String _formatDate(DateTime? date) {
  if (date == null) return '—';
  final now = DateTime.now();
  final diff = now.difference(date);
  if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} د';
  if (diff.inHours < 24) return 'منذ ${diff.inHours} س';
  if (diff.inDays == 1) return 'أمس';
  if (diff.inDays < 7) return 'منذ ${diff.inDays} أيام';
  return '${date.day}/${date.month}/${date.year}';
}

/// محتوى تبويب الطلبات — تصميم عصري متناسق مع التطبيق (GetX + بيانات وهمية).
class OrdersContent extends GetView<OrdersController> {
  const OrdersContent({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return Obx(() {
      if (!auth.isAuthenticated) {
        return _GuestOrdersState();
      }
      if (controller.isLoading.value && controller.orders.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.orders.isEmpty) {
        return controller.error.value != null
            ? _ErrorOrdersState(message: controller.error.value!)
            : _EmptyOrdersState();
      }
      return RefreshIndicator(
        onRefresh: controller.refresh,
        color: Theme.of(context).colorScheme.primary,
        child: CustomScrollView(
          controller: controller.scrollController,
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                child: _OrdersHeader(),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: _SectionTitle(title: 'طلباتك'),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final order = controller.ordersByNewest[index];
                    return Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.md),
                      child: _OrderCard(
                        order: order,
                        formatPrice: formatPrice,
                        formatDate: _formatDate,
                      ),
                    );
                  },
                  childCount: controller.ordersByNewest.length,
                ),
              ),
            ),
            if (controller.loadingMore.value)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Center(child: SizedBox(
                    width: 24.w,
                    height: 24.h,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )),
                ),
              ),
            SliverToBoxAdapter(child: SizedBox(height: 100.h)),
          ],
        ),
      );
    });
  }
}

class _OrdersHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradientColors = isDark
        ? [colorScheme.primaryContainer, colorScheme.surfaceContainerHigh]
        : [AppColors.primaryLight, AppColors.primaryBeige.withValues(alpha: 0.6)];
    final textColor = isDark ? colorScheme.onPrimaryContainer : AppColors.primaryDark;
    final subTextColor = isDark ? colorScheme.onSurfaceVariant : AppColors.textSecondary;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 20.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long_rounded, size: 28.sp, color: textColor),
              SizedBox(width: 10.w),
              Text(
                'طلباتي',
                style: TextStyle(
                  fontFamily: kFontFamilyCairo,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            'تتبع طلباتك وتاريخ التوصيل',
            style: TextStyle(
              fontFamily: kFontFamilyCairo,
              fontSize: 14.sp,
              color: subTextColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      title,
      style: TextStyle(
        fontFamily: kFontFamilyCairo,
        fontSize: 18.sp,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.formatPrice,
    required this.formatDate,
  });

  final Order order;
  final String Function(double) formatPrice;
  final String Function(DateTime?) formatDate;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? colorScheme.surfaceContainerHighest : Colors.white;
    final borderColor = isDark ? colorScheme.outline.withValues(alpha: 0.3) : AppColors.border;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20.r),
        child: InkWell(
          onTap: () {
            Get.toNamed('/order-detail', arguments: order.id);
          },
          borderRadius: BorderRadius.circular(20.r),
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.isMultiShop ? 'طلب من عدة محلات' : (order.shopName ?? 'متجر'),
                            style: TextStyle(
                              fontFamily: kFontFamilyCairo,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            formatDate(order.createdAt),
                            style: TextStyle(
                              fontFamily: kFontFamilyCairo,
                              fontSize: 13.sp,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    OrderStatusChip(status: order.status),
                  ],
                ),
                SizedBox(height: 12.h),
                if (order.allItems.isEmpty)
                  Padding(
                    padding: EdgeInsets.only(bottom: 4.h),
                    child: Row(
                      children: [
                        Icon(Icons.mic_rounded, size: 16.sp, color: colorScheme.primary),
                        SizedBox(width: 6.w),
                        Text(
                          'طلب صوتي',
                          style: TextStyle(
                            fontFamily: kFontFamilyCairo,
                            fontSize: 14.sp,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  ...order.allItems.take(3).map(
                    (item) => Padding(
                      padding: EdgeInsets.only(bottom: 4.h),
                      child: Row(
                        children: [
                          Text(
                            '• ',
                            style: TextStyle(
                              fontFamily: kFontFamilyCairo,
                              fontSize: 14.sp,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${item.name} × ${item.quantity}',
                              style: TextStyle(
                                fontFamily: kFontFamilyCairo,
                                fontSize: 14.sp,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (order.allItems.length > 3)
                    Padding(
                      padding: EdgeInsets.only(bottom: 4.h),
                      child: Text(
                        '+ ${order.allItems.length - 3} عنصر آخر',
                        style: TextStyle(
                          fontFamily: kFontFamilyCairo,
                          fontSize: 12.sp,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                ],
                if (order.notes != null && order.notes!.isNotEmpty) ...[
                  SizedBox(height: 8.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.note_rounded, size: 16.sp, color: colorScheme.primary),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          order.notes!.length > 50 ? '${order.notes!.substring(0, 50)}...' : order.notes!,
                          style: TextStyle(
                            fontFamily: kFontFamilyCairo,
                            fontSize: 12.sp,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                if (order.notesAudioUrl != null && order.notesAudioUrl!.isNotEmpty) ...[
                  SizedBox(height: 8.h),
                  OrderNoteAudioPlayer(audioUrl: order.notesAudioUrl),
                ],
                SizedBox(height: 12.h),
                Divider(height: 1, color: borderColor),
                SizedBox(height: 10.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'الإجمالي',
                      style: TextStyle(
                        fontFamily: kFontFamilyCairo,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      formatPrice(order.grandTotal),
                      style: TextStyle(
                        fontFamily: kFontFamilyCairo,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class _ErrorOrdersState extends StatelessWidget {
  const _ErrorOrdersState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 80.sp,
              color: colorScheme.error.withValues(alpha: 0.7),
            ),
            AppSpacing.verticalLg,
            Text(
              message,
              style: TextStyle(
                fontFamily: kFontFamilyCairo,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyOrdersState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80.sp,
              color: colorScheme.primary.withValues(alpha: 0.5),
            ),
            AppSpacing.verticalLg,
            Text(
              'لا توجد طلبات',
              style: TextStyle(
                fontFamily: kFontFamilyCairo,
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            AppSpacing.verticalSm,
            Text(
              'عند تنفيذ طلبك سيظهر هنا',
              style: TextStyle(
                fontFamily: kFontFamilyCairo,
                fontSize: 14.sp,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _GuestOrdersState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80.sp,
              color: colorScheme.primary.withValues(alpha: 0.5),
            ),
            AppSpacing.verticalLg,
            Text(
              'سجّل الدخول لمتابعة طلباتك',
              style: TextStyle(
                fontFamily: kFontFamilyCairo,
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.verticalSm,
            Text(
              'عند إتمام طلب سينشأ لك حساب تلقائياً، أو سجّل الدخول لمتابعة طلباتك الحالية.',
              style: TextStyle(
                fontFamily: kFontFamilyCairo,
                fontSize: 14.sp,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.verticalLg,
            FilledButton(
              onPressed: () => Get.toNamed('/login'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                foregroundColor: AppColors.primaryLight,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              child: Text(
                'تسجيل الدخول',
                style: TextStyle(
                  fontFamily: kFontFamilyCairo,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
