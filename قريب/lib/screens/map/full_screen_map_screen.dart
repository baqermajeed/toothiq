import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../controllers/full_screen_map_controller.dart';
import '../../core/config/api_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../utils/launch_phone_utils.dart';
import '../../utils/map_debug_logger.dart';
import '../../widgets/common/app_spacing.dart';

void _showDriverDetailsSheet(BuildContext context, FullScreenMapController controller) {
  final colorScheme = Theme.of(context).colorScheme;
  final name = controller.driverName.value ?? 'السائق';
  final phone = controller.driverPhone.value;
  final photoUrl = controller.driverPhoto.value != null
      ? ApiConfig.userImageUrl(controller.driverPhoto.value!)
      : null;
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: colorScheme.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'تفاصيل السائق',
              style: TextStyle(
                fontFamily: kFontFamilyCairo,
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 20.h),
            CircleAvatar(
              radius: 48.r,
              backgroundColor: colorScheme.surfaceContainerHighest,
              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
              child: photoUrl == null
                  ? Icon(Icons.person_rounded, size: 48.sp, color: colorScheme.onSurfaceVariant)
                  : null,
            ),
            SizedBox(height: 16.h),
            Text(
              name,
              style: TextStyle(
                fontFamily: kFontFamilyCairo,
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            if (phone != null && phone.isNotEmpty) ...[
              SizedBox(height: 8.h),
              Text(
                phone,
                style: TextStyle(
                  fontFamily: kFontFamilyCairo,
                  fontSize: 15.sp,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    launchPhoneCall(phone);
                  },
                  icon: Icon(Icons.phone_rounded, size: 22.sp),
                  label: Text(
                    'اتصال',
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
          ],
        ),
      ),
    ),
  );
}

/// شاشة الخريطة بحجم كامل — للعرض أو لاختيار موقع التوصيل.
class FullScreenMapScreen extends GetView<FullScreenMapController> {
  const FullScreenMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Obx(() {
              final mapReady = controller.mapReady.value;
              if (!mapReady) {
                return Positioned.fill(
                  child: ColoredBox(
                    color: colorScheme.surfaceContainerHighest,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 40.w,
                            height: 40.h,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.primary,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'جاري تحميل الخريطة...',
                            style: TextStyle(
                              fontFamily: kFontFamilyCairo,
                              fontSize: 16.sp,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              final lat = controller.centerLat;
              final lng = controller.centerLng;
              final selLat = controller.selectedLat.value;
              final selLng = controller.selectedLng.value;
              final hasMarker = selLat != null && selLng != null;
              final hasDriver = controller.hasDriverLocation;
              final dLat = controller.driverLat.value;
              final dLng = controller.driverLng.value;

              final Set<Marker> markers = {};
              if (hasMarker) {
                markers.add(
                  Marker(
                    markerId: const MarkerId('delivery'),
                    position: LatLng(selLat, selLng),
                    anchor: const Offset(0.5, 1.0),
                    icon: controller.customerIcon.value ?? BitmapDescriptor.defaultMarker,
                    infoWindow: const InfoWindow(
                      title: 'موقع التوصيل',
                      snippet: 'موقع العميل',
                    ),
                  ),
                );
              }
              if (hasDriver && dLat != null && dLng != null) {
                final driverName = controller.driverName.value;
                markers.add(
                  Marker(
                    markerId: const MarkerId('driver'),
                    position: LatLng(dLat, dLng),
                    icon: controller.driverIcon.value ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
                    infoWindow: InfoWindow(
                      title: driverName?.isNotEmpty == true ? driverName! : 'السائق',
                      snippet: 'اضغط للمزيد من التفاصيل',
                    ),
                  ),
                );
              }
              for (var i = 0; i < controller.shopLocations.length; i++) {
                final shop = controller.shopLocations[i];
                final sLat = shop['lat'] is num ? (shop['lat'] as num).toDouble() : null;
                final sLng = shop['lng'] is num ? (shop['lng'] as num).toDouble() : null;
                final name = shop['name'] as String?;
                if (sLat != null && sLng != null) {
                  markers.add(
                    Marker(
                      markerId: MarkerId('shop-$i'),
                      position: LatLng(sLat, sLng),
                      icon: controller.shopIcon.value ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
                      infoWindow: InfoWindow(
                        title: name?.isNotEmpty == true ? name! : 'المحل',
                        snippet: 'موقع المحل الذي طلبت منه',
                      ),
                    ),
                  );
                }
              }

              final Set<Polyline> polylines = {};
              if (!controller.isPickMode && hasMarker && hasDriver && dLat != null && dLng != null) {
                // إذا كان لدينا طريق فعلي من Directions API، استخدمه
                if (controller.routePoints.isNotEmpty) {
                  polylines.add(
                    Polyline(
                      polylineId: const PolylineId('route'),
                      points: controller.routePoints,
                      color: Colors.blue,
                      width: 6.r.toInt(),
                      geodesic: true,
                    ),
                  );
                } else if (!controller.isLoadingRoute.value) {
                  // إذا فشل تحميل الطريق، استخدم خط مستقيم كبديل
                  polylines.add(
                    Polyline(
                      polylineId: const PolylineId('route'),
                      points: [
                        LatLng(dLat, dLng),
                        LatLng(selLat, selLng),
                      ],
                      color: Colors.blue.withValues(alpha: 0.6),
                      width: 5.r.toInt(),
                      patterns: [PatternItem.dash(20), PatternItem.gap(10)],
                    ),
                  );
                }
              }

              MapDebugLogger.googleMapBuildStart();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                controller.setLabelsData(controller.buildLabelsData());
              });
              return KeyedSubtree(
                key: const ValueKey('fullmap'),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                  target: LatLng(lat, lng),
                  zoom: hasMarker || hasDriver ? 15 : 10,
                ),
                markers: markers,
                polylines: polylines,
                onMapCreated: (GoogleMapController c) {
                  MapDebugLogger.onMapCreated();
                  controller.setMapController(c);
                  controller.setLabelsData(controller.buildLabelsData());
                  if (!controller.isPickMode) {
                    double? minLat;
                    double? maxLat;
                    double? minLng;
                    double? maxLng;
                    if (hasMarker) {
                      minLat = selLat;
                      maxLat = selLat;
                      minLng = selLng;
                      maxLng = selLng;
                    }
                    if (hasDriver && dLat != null && dLng != null) {
                      minLat = minLat != null ? (dLat < minLat ? dLat : minLat) : dLat;
                      maxLat = maxLat != null ? (dLat > maxLat ? dLat : maxLat) : dLat;
                      minLng = minLng != null ? (dLng < minLng ? dLng : minLng) : dLng;
                      maxLng = maxLng != null ? (dLng > maxLng ? dLng : maxLng) : dLng;
                    }
                    for (final shop in controller.shopLocations) {
                      final sLat = shop['lat'] is num ? (shop['lat'] as num).toDouble() : null;
                      final sLng = shop['lng'] is num ? (shop['lng'] as num).toDouble() : null;
                      if (sLat != null && sLng != null) {
                        minLat = minLat != null ? (sLat < minLat ? sLat : minLat) : sLat;
                        maxLat = maxLat != null ? (sLat > maxLat ? sLat : maxLat) : sLat;
                        minLng = minLng != null ? (sLng < minLng ? sLng : minLng) : sLng;
                        maxLng = maxLng != null ? (sLng > maxLng ? sLng : maxLng) : sLng;
                      }
                    }
                    if (minLat != null && maxLat != null && minLng != null && maxLng != null) {
                      final bounds = LatLngBounds(
                        southwest: LatLng(minLat, minLng),
                        northeast: LatLng(maxLat, maxLng),
                      );
                      c.moveCamera(CameraUpdate.newLatLngBounds(bounds, 80));
                    }
                  }
                },
                onTap: controller.isPickMode
                    ? (LatLng position) {
                        controller.setPosition(position.latitude, position.longitude);
                      }
                    : null,
                onCameraMove: (_) => controller.onCameraMoved(),
                myLocationButtonEnabled: true,
                zoomControlsEnabled: false,
              ),
            );
            }),
            Positioned.fill(
              child: IgnorePointer(
                child: Obx(() {
                  if (controller.isPickMode || controller.labelOverlays.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Stack(
                    clipBehavior: Clip.none,
                    children: controller.labelOverlays.map((e) {
                      final x = (e['x'] as num?)?.toDouble() ?? 0.0;
                      final y = (e['y'] as num?)?.toDouble() ?? 0.0;
                      final title = e['title'] as String? ?? '';
                      final snippet = e['snippet'] as String? ?? '';
                      const labelWidth = 100.0;
                      return Positioned(
                        left: x - labelWidth / 2,
                        top: y,
                        width: labelWidth,
                        child: Material(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(6.r),
                          elevation: 2,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 4.h),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(
                                    fontFamily: kFontFamilyCairo,
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (snippet.isNotEmpty) ...[
                                  SizedBox(height: 2.h),
                                  Text(
                                    snippet,
                                    style: TextStyle(
                                      fontFamily: kFontFamilyCairo,
                                      fontSize: 9.sp,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.95),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.close_rounded, size: 24.sp),
                          onPressed: () => Get.back(),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            controller.isPickMode
                                ? 'اختر موقع التوصيل على الخريطة'
                                : (controller.hasDriverLocation ? 'موقع التوصيل وموقع السائق' : 'موقع التوصيل'),
                            style: TextStyle(
                              fontFamily: kFontFamilyCairo,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(8.w, 4.h, 8.w, 8.h),
                      child: TextField(
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.left,
                        decoration: InputDecoration(
                          hintText: 'ابحث عن عنوان أو مكان...',
                          hintStyle: TextStyle(
                            fontFamily: kFontFamilyCairo,
                            fontSize: 14.sp,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          prefixIcon: Obx(() {
                            if (controller.isSearching.value) {
                              return Padding(
                                padding: EdgeInsets.all(12.r),
                                child: SizedBox(
                                  width: 20.w,
                                  height: 20.h,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              );
                            }
                            return Icon(Icons.search_rounded, size: 24.sp, color: colorScheme.primary);
                          }),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14.r),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                        ),
                        style: TextStyle(
                          fontFamily: kFontFamilyCairo,
                          fontSize: 14.sp,
                          color: colorScheme.onSurface,
                        ),
                        onSubmitted: (value) => controller.searchLocation(value),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (controller.isPickMode)
              Positioned(
                bottom: 24.h,
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(16.r),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: controller.confirm,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryDark,
                        foregroundColor: AppColors.primaryLight,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                      ),
                      child: Text(
                        'تأكيد الموقع',
                        style: TextStyle(
                          fontFamily: kFontFamilyCairo,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (!controller.isPickMode &&
                (controller.driverName.value != null || controller.driverPhone.value != null))
              Positioned(
                bottom: 24.h,
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(16.r),
                  child: InkWell(
                    onTap: () => _showDriverDetailsSheet(context, controller),
                    borderRadius: BorderRadius.circular(16.r),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                      child: Row(
                        children: [
                          Icon(Icons.person_rounded, size: 28.sp, color: AppColors.primaryDark),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              'تفاصيل السائق',
                              style: TextStyle(
                                fontFamily: kFontFamilyCairo,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Icon(Icons.chevron_left_rounded, size: 28.sp, color: colorScheme.onSurfaceVariant),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
