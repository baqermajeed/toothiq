import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controllers/order_detail_controller.dart';
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
  return '${date.day}/${date.month}/${date.year}';
}

/// شاشة تفاصيل الطلب — بيانات الطلب + خريطة موقع التوصيل (مرسل الطلب).
class OrderDetailScreen extends GetView<OrderDetailController> {
  const OrderDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20.sp),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'تفاصيل الطلب',
          style: TextStyle(
            fontFamily: kFontFamilyCairo,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.order.value == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.error.value != null) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 48.sp,
                    color: AppColors.error,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    controller.error.value!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: kFontFamilyCairo,
                      fontSize: 16.sp,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        final order = controller.order.value;
        if (order == null) {
          return const Center(child: Text('لا يوجد طلب'));
        }
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _OrderInfoCard(
                order: order,
                formatPrice: formatPrice,
                formatDate: _formatDate,
              ),
              AppSpacing.verticalLg,
              const _DeliveryMapSection(),
            ],
          ),
        );
      }),
    );
  }
}

class _OrderInfoCard extends StatelessWidget {
  const _OrderInfoCard({
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
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.04),
            blurRadius: 12.r,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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
                        fontSize: 18.sp,
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
          SizedBox(height: 16.h),
          if (order.allItems.isEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                children: [
                  Icon(Icons.mic_rounded, size: 18.sp, color: colorScheme.primary),
                  SizedBox(width: 8.w),
                  Text(
                    'طلب صوتي — استمع للملاحظة الصوتية أدناه',
                    style: TextStyle(
                      fontFamily: kFontFamilyCairo,
                      fontSize: 14.sp,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          if (order.shopPortions != null && order.shopPortions!.isNotEmpty)
            ...order.shopPortions!.expand((portion) => [
                  Padding(
                    padding: EdgeInsets.only(bottom: 4.h),
                    child: Text(
                      portion.shopName ?? 'محل',
                      style: TextStyle(
                        fontFamily: kFontFamilyCairo,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  ...portion.items.map(
                    (item) => Padding(
                      padding: EdgeInsets.only(bottom: 8.h, right: 12.w),
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
                            ),
                          ),
                          Text(
                            formatPrice(item.lineTotal),
                            style: TextStyle(
                              fontFamily: kFontFamilyCairo,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ]),
          if (order.allItems.isNotEmpty &&
              (order.shopPortions == null || order.shopPortions!.isEmpty))
            ...order.items.map(
              (item) => Padding(
                padding: EdgeInsets.only(bottom: 8.h),
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
                      ),
                    ),
                    Text(
                      formatPrice(item.lineTotal),
                      style: TextStyle(
                        fontFamily: kFontFamilyCairo,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Divider(height: 24.h, color: borderColor),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'المجموع الفرعي',
                style: TextStyle(
                  fontFamily: kFontFamilyCairo,
                  fontSize: 14.sp,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                formatPrice(order.totalPrice),
                style: TextStyle(
                  fontFamily: kFontFamilyCairo,
                  fontSize: 14.sp,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'رسوم التوصيل',
                style: TextStyle(
                  fontFamily: kFontFamilyCairo,
                  fontSize: 14.sp,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                formatPrice(order.deliveryFee),
                style: TextStyle(
                  fontFamily: kFontFamilyCairo,
                  fontSize: 14.sp,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الإجمالي',
                style: TextStyle(
                  fontFamily: kFontFamilyCairo,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                formatPrice(order.grandTotal),
                style: TextStyle(
                  fontFamily: kFontFamilyCairo,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          if (order.notes != null && order.notes!.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Text(
              'ملاحظات: ${order.notes}',
              style: TextStyle(
                fontFamily: kFontFamilyCairo,
                fontSize: 13.sp,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (order.notesAudioUrl != null && order.notesAudioUrl!.isNotEmpty) ...[
            SizedBox(height: 12.h),
            OrderNoteAudioPlayer(audioUrl: order.notesAudioUrl),
          ],
        ],
      ),
    );
  }
}

class _DeliveryMapSection extends StatelessWidget {
  const _DeliveryMapSection();

  /// عرض قسم الخريطة فقط عندما تكون الحالة «قيد التوصيل» (في الطريق).
  /// عند «تم التوصيل» لا نعرض الخريطة. عند «قيد التوصيل» نعرض زر يفتح الخريطة بحجم كامل.
  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<OrderDetailController>();
    return Obx(() {
      final order = ctrl.order.value;
      if (order == null) return const SizedBox.shrink();
      // لا نعرض الخريطة أبداً في صفحة التفاصيل عند «تم التوصيل»
      if (order.status == OrderStatus.delivered) return const SizedBox.shrink();
      // زر «تتبع طلبي على الخريطة» يظهر فقط عندما الطلب «قيد التوصيل» (في الطريق)
      if (order.status != OrderStatus.onTheWay) return const SizedBox.shrink();

      final hasDriver = ctrl.hasDriverLocation;
      final hasDelivery = ctrl.hasDeliveryLocation && order.deliveryLat != null && order.deliveryLng != null;
      final canOpenMap = hasDelivery || hasDriver;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: canOpenMap
                  ? () {
                      Get.toNamed(
                        '/full-screen-map',
                        arguments: {
                          'lat': hasDelivery ? order.deliveryLat : order.driverLat,
                          'lng': hasDelivery ? order.deliveryLng : order.driverLng,
                          'driverLat': order.driverLat,
                          'driverLng': order.driverLng,
                          'driverName': order.driverName,
                          'driverPhone': order.driverPhone,
                          'driverPhoto': order.driverPhoto,
                          'mode': 'view',
                          'orderId': order.id,
                          'shopLocations': order.shopLocationsForMap,
                        },
                      );
                    }
                  : null,
              icon: Icon(Icons.map_rounded, size: 22.sp),
              label: Text(
                'تتبع طلبي على الخريطة',
                style: TextStyle(
                  fontFamily: kFontFamilyCairo,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                foregroundColor: AppColors.primaryLight,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}
