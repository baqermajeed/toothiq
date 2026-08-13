import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../controller/driver_orders_controller.dart';
import '../../model/partner_order.dart';
import '../../utils/app_colors.dart';
import '../../widget/my_text.dart';

class DriverOrderMapPage extends StatefulWidget {
  const DriverOrderMapPage({super.key, required this.order});

  final PartnerOrder order;

  @override
  State<DriverOrderMapPage> createState() => _DriverOrderMapPageState();
}

class _DriverOrderMapPageState extends State<DriverOrderMapPage> {
  GoogleMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DriverOrdersController>();
    final order = widget.order;

    final shopLat = order.shopLat ?? 33.3128;
    final shopLng = order.shopLng ?? 44.4250;
    final customerLat = order.customerLat ?? 33.3152;
    final customerLng = order.customerLng ?? 44.3661;

    final shop = LatLng(shopLat, shopLng);
    final customer = LatLng(customerLat, customerLng);
    final mid = LatLng(
      (shopLat + customerLat) / 2,
      (shopLng + customerLng) / 2,
    );

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: MyText('طلب #${order.orderNumber}', fontSize: 18.sp),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: mid, zoom: 12.5),
              markers: {
                Marker(
                  markerId: const MarkerId('shop'),
                  position: shop,
                  infoWindow: InfoWindow(
                    title: 'المتجر',
                    snippet: order.shopName,
                  ),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueAzure,
                  ),
                ),
                Marker(
                  markerId: const MarkerId('customer'),
                  position: customer,
                  infoWindow: InfoWindow(
                    title: 'الزبون',
                    snippet: order.customerName,
                  ),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueOrange,
                  ),
                ),
              },
              polylines: {
                Polyline(
                  polylineId: const PolylineId('route'),
                  points: [shop, customer],
                  color: AppColors.primary,
                  width: 4,
                ),
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              onMapCreated: (c) => _mapController = c,
            ),
          ),
          Expanded(
            flex: 4,
            child: Obx(() {
              final live = controller.findOrder(order.id) ?? order;

              return SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _LocationTile(
                      icon: Icons.storefront,
                      title: 'موقع المتجر',
                      subtitle: order.shopAddress,
                      onOpenMaps: () => _openMaps(shopLat, shopLng),
                    ),
                    SizedBox(height: 10.h),
                    _LocationTile(
                      icon: Icons.person_pin_circle_outlined,
                      title: 'موقع الزبون',
                      subtitle: order.customerAddress,
                      onOpenMaps: () => _openMaps(customerLat, customerLng),
                    ),
                    SizedBox(height: 10.h),
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MyText(live.customerName, fontSize: 14.sp),
                          SizedBox(height: 4.h),
                          MyText(
                            '${live.formattedTotal} · ${live.status.label}',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 14.h),
                    if (live.status != PartnerOrderStatus.onTheWay &&
                        live.status != PartnerOrderStatus.delivered)
                      ElevatedButton(
                        onPressed: () async {
                          await controller.startDelivery(live.id);
                          Get.snackbar(
                            'التوصيل',
                            'بدأ التوصيل ومشاركة الموقع مع العميل',
                          );
                        },
                        style: _btn(),
                        child: MyText(
                          'بدء التوصيل ومشاركة الموقع',
                          fontSize: 14.sp,
                          color: Colors.white,
                        ),
                      ),
                    if (live.status == PartnerOrderStatus.onTheWay) ...[
                      ElevatedButton(
                        onPressed: () async {
                          await controller.completeDelivery(live.id);
                          Get.back();
                          Get.snackbar('تم', 'تم تسليم الطلب');
                        },
                        style: _btn(color: AppColors.success),
                        child: MyText(
                          'تأكيد التسليم',
                          fontSize: 14.sp,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      if (controller.isSharingLocation.value)
                        MyText(
                          'يتم إرسال موقعك لتطبيق العميل كل 5 ثوانٍ',
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w500,
                          color: AppColors.success,
                          textAlign: TextAlign.center,
                        ),
                    ],
                    SizedBox(height: 8.h),
                    OutlinedButton.icon(
                      onPressed: () =>
                          launchUrl(Uri.parse('tel:${order.customerPhone}')),
                      icon: const Icon(Icons.phone),
                      label: MyText('اتصال بالزبون', fontSize: 13.sp),
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size(double.infinity, 46.h),
                        foregroundColor: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  ButtonStyle _btn({Color color = AppColors.primary}) => ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: Size(double.infinity, 48.h),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
      );

  Future<void> _openMaps(double lat, double lng) async {
    final wazeApp = Uri.parse('waze://?ll=$lat,$lng&navigate=yes');
    final wazeWeb = Uri.parse('https://waze.com/ul?ll=$lat,$lng&navigate=yes');
    try {
      if (await canLaunchUrl(wazeApp)) {
        await launchUrl(wazeApp, mode: LaunchMode.externalApplication);
        return;
      }
      final launched = await launchUrl(
        wazeWeb,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        Get.snackbar('ويز', 'تعذر فتح تطبيق ويز');
      }
    } catch (_) {
      Get.snackbar('ويز', 'ثبّت تطبيق ويز لفتح المسار');
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

class _LocationTile extends StatelessWidget {
  const _LocationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onOpenMaps,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onOpenMaps;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 26.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText(title, fontSize: 13.sp),
                SizedBox(height: 2.h),
                MyText(
                  subtitle,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onOpenMaps,
            icon: Icon(Icons.open_in_new, color: AppColors.primary, size: 20.sp),
          ),
        ],
      ),
    );
  }
}
