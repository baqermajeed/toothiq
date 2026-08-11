import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../controller/map_pick_controller.dart';
import '../../utils/app_colors.dart';
import '../../widget/my_text.dart';
import '../../widget/primary_button.dart';

class MapPickResult {
  const MapPickResult({
    required this.lat,
    required this.lng,
  });

  final double lat;
  final double lng;
}

class MapPickPage extends GetView<MapPickController> {
  const MapPickPage({super.key});

  static Future<MapPickResult?> open({
    double? lat,
    double? lng,
  }) async {
    final result = await Get.to<LatLng>(
      () => const MapPickPage(),
      binding: BindingsBuilder(() {
        Get.put(MapPickController());
      }),
      arguments: {
        'lat': ?lat,
        'lng': ?lng,
      },
    );
    if (result == null) return null;
    return MapPickResult(lat: result.latitude, lng: result.longitude);
  }

  Future<void> _search(BuildContext context) async {
    final queryCtrl = TextEditingController();
    final query = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('بحث عن موقع'),
          content: TextField(
            controller: queryCtrl,
            textDirection: TextDirection.rtl,
            decoration: const InputDecoration(
              hintText: 'اكتب اسم المنطقة أو العنوان',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, queryCtrl.text.trim()),
              child: const Text('بحث'),
            ),
          ],
        );
      },
    );
    if (query == null || query.isEmpty) return;
    await controller.searchLocation(query);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              Obx(() {
                if (!controller.mapReady.value) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }
                return GoogleMap(
                  key: const ValueKey('delivery-map'),
                  initialCameraPosition: controller.initialCamera,
                  onMapCreated: controller.onMapCreated,
                  markers: Set<Marker>.from(controller.markers),
                  onTap: (position) {
                    controller.setPosition(
                      position.latitude,
                      position.longitude,
                      animate: false,
                    );
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                );
              }),
              Positioned(
                top: 8.h,
                left: 8.w,
                right: 8.w,
                child: Material(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(14.r),
                  elevation: 2,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: Get.back,
                          icon: const Icon(Icons.close_rounded),
                        ),
                        Expanded(
                          child: MyText(
                            'اختر موقع التوصيل على الخريطة',
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.productTitle,
                          ),
                        ),
                        Obx(
                          () => IconButton(
                            onPressed: controller.isSearching.value
                                ? null
                                : () => _search(context),
                            icon: const Icon(Icons.search_rounded),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 16.w,
                right: 16.w,
                bottom: 16.h,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Obx(() {
                      final loading = controller.isLocating.value;
                      return OutlinedButton.icon(
                        onPressed: loading ? null : controller.useCurrentLocation,
                        icon: loading
                            ? SizedBox(
                                width: 20.w,
                                height: 20.h,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              )
                            : const Icon(Icons.my_location_rounded),
                        label: Text(
                          loading ? 'جاري تحديد الموقع...' : 'موقعي الحالي',
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          minimumSize: Size(double.infinity, 48.h),
                        ),
                      );
                    }),
                    SizedBox(height: 10.h),
                    PrimaryButton(
                      label: 'تأكيد الموقع',
                      onPressed: controller.confirm,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
