import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../model/order_detail_model.dart';
import '../../utils/app_colors.dart';
import '../../widget/my_text.dart';
import '../../widget/orders/order_detail_app_bar.dart';
import '../../widget/primary_button.dart';

/// تتبع مباشر لموقع المندوب — يتحدّث عبر WebSocket (مثل قريب).
class OrderTrackingPage extends StatelessWidget {
  const OrderTrackingPage({
    super.key,
    required this.orderId,
    required this.detail,
    required this.driverLat,
    required this.driverLng,
  });

  final String orderId;
  final OrderDetailModel detail;
  final Rxn<double> driverLat;
  final Rxn<double> driverLng;

  static void open({
    required String orderId,
    required OrderDetailModel detail,
    required Rxn<double> driverLat,
    required Rxn<double> driverLng,
  }) {
    Get.to(
      () => OrderTrackingPage(
        orderId: orderId,
        detail: detail,
        driverLat: driverLat,
        driverLng: driverLng,
      ),
    );
  }

  Future<void> _openMaps(double lat, double lng) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _callDriver(String? phone) async {
    final normalized = phone?.replaceAll(RegExp(r'\s+'), '');
    if (normalized == null || normalized.isEmpty) return;
    final uri = Uri.parse('tel:$normalized');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: const OrderDetailAppBar(title: 'تتبع الطلب'),
        body: Obx(() {
          final lat = driverLat.value ?? detail.driverLat;
          final lng = driverLng.value ?? detail.driverLng;
          final hasDriver = lat != null && lng != null;

          return SingleChildScrollView(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: AppColors.orderDetailCardBorder),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.delivery_dining_rounded,
                        size: 56.sp,
                        color: AppColors.primaryDark,
                      ),
                      SizedBox(height: 12.h),
                      MyText(
                        'طلبك في الطريق',
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.productTitle,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8.h),
                      MyText(
                        hasDriver
                            ? 'يتم تحديث موقع المندوب مباشرة'
                            : 'بانتظار موقع المندوب...',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),
                if (detail.driverName != null && detail.driverName!.isNotEmpty)
                  _InfoTile(
                    icon: Icons.person_outline,
                    label: 'المندوب',
                    value: detail.driverName!,
                  ),
                if (hasDriver) ...[
                  SizedBox(height: 12.h),
                  _InfoTile(
                    icon: Icons.location_on_outlined,
                    label: 'آخر موقع',
                    value: '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
                  ),
                ],
                SizedBox(height: 24.h),
                if (hasDriver) ...[
                  PrimaryButton(
                    label: 'فتح على الخريطة',
                    onPressed: () {
                      final dLat = driverLat.value ?? detail.driverLat;
                      final dLng = driverLng.value ?? detail.driverLng;
                      if (dLat == null || dLng == null) return;
                      _openMaps(dLat, dLng);
                    },
                  ),
                ],
                if (detail.driverPhone != null &&
                    detail.driverPhone!.isNotEmpty) ...[
                  SizedBox(height: 12.h),
                  OutlinedButton.icon(
                    onPressed: () => _callDriver(detail.driverPhone),
                    icon: const Icon(Icons.phone_rounded),
                    label: const Text('اتصال بالمندوب'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryDark,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText(
                  label,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
                SizedBox(height: 2.h),
                MyText(
                  value,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
