import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../core/errors/api_exception.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../models/order.dart';
import '../widgets/common/app_toast.dart';
import '../widgets/dialogs/delivery_location_required_dialog.dart';
import '../widgets/dialogs/guest_register_dialog.dart';
import '../widgets/dialogs/zone_not_supported_dialog.dart';
import '../widgets/dialogs/order_success_credentials_dialog.dart';
import '../models/shop.dart';
import '../services/order_service.dart';
import 'app_location_controller.dart';
import 'auth_controller.dart';
import 'main_shell_controller.dart';
import 'orders_controller.dart';

/// تحكم شاشة طلب الشراء بالمقطع الصوتي: اختيار محلات متعددة، تسجيل صوت، إرسال لجميع المحلات المختارة.
/// عندما تكون المنطقة «طلب صوتي فقط» لا يُعرض اختيار المحلات ويُرسل الطلب بدون محل.
class VoiceOrderController extends GetxController {
  final RxList<Shop> shops = <Shop>[].obs;
  final RxBool shopsLoading = true.obs;
  /// true عندما تكون المنطقة تدعم الطلب الصوتي فقط (بدون محلات).
  final RxBool isVoiceOrderOnlyZone = false.obs;
  /// المحلات التي اختارها المستخدم لإرسال الطلب الصوتي لها.
  final RxList<Shop> selectedShops = <Shop>[].obs;
  final Rxn<String> audioPath = Rxn<String>();
  final RxBool isRecording = false.obs;
  final RxBool isUploading = false.obs;
  final RxBool isSubmitting = false.obs;
  final Rxn<String> errorMessage = Rxn<String>();

  final AudioRecorder _recorder = AudioRecorder();

  bool isShopSelected(Shop shop) => selectedShops.any((s) => s.id == shop.id);

  void toggleShop(Shop shop) {
    final idx = selectedShops.indexWhere((s) => s.id == shop.id);
    if (idx >= 0) {
      selectedShops.removeAt(idx);
    } else {
      selectedShops.add(shop);
    }
  }

  @override
  void onInit() {
    super.onInit();
    loadShops();
  }

  @override
  void onClose() {
    _recorder.dispose();
    super.onClose();
  }

  Future<void> loadShops() async {
    shopsLoading.value = true;
    try {
      final auth = Get.find<AuthController>();
      final api = auth.apiClient;
      double? lng;
      double? lat;
      final user = auth.user.value;
      if (user?.location is Map<String, dynamic>) {
        final loc = user!.location as Map<String, dynamic>;
        final coords = loc['coordinates'];
        if (coords is List && coords.length >= 2) {
          lng = (coords[0] as num).toDouble();
          lat = (coords[1] as num).toDouble();
        }
      }
      if (lng == null || lat == null) {
        final appLoc = Get.find<AppLocationController>();
        if (appLoc.hasLocation) {
          lng = appLoc.lng;
          lat = appLoc.lat;
        }
      }
      final list = await api.getShops(lng: lng, lat: lat);
      shops.value = list;
      if (list.isEmpty && lng != null && lat != null) {
        final check = await api.checkVoiceOrderZone(lng, lat);
        isVoiceOrderOnlyZone.value = check.inside;
      } else {
        isVoiceOrderOnlyZone.value = false;
      }
    } catch (e) {
      shops.clear();
      isVoiceOrderOnlyZone.value = false;
      errorMessage.value = e is ApiException ? e.message : 'فشل تحميل المحلات';
    } finally {
      shopsLoading.value = false;
    }
  }

  Future<void> startRecording() async {
    errorMessage.value = null;
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      AppToast.show(
        'صلاحية الميكروفون',
        'نحتاج صلاحية الميكروفون لتسجيل مقطع الطلب الصوتي وإرساله للمحل. يرجى السماح من الإعدادات إن رغبت بالتسجيل.',
        type: ToastType.warning,
        duration: const Duration(seconds: 5),
      );
      return;
    }
    try {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/voice_order_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc, sampleRate: 44100), path: path);
      isRecording.value = true;
    } catch (e) {
      AppToast.show(
        'التسجيل',
        'فشل بدء التسجيل. نحتاج صلاحية الميكروفون لتسجيل الطلب الصوتي وإرساله للمحل. تأكد من منح الصلاحية من الإعدادات.',
        type: ToastType.warning,
        duration: const Duration(seconds: 5),
      );
    }
  }

  /// إيقاف التسجيل وإرجاع مسار الملف (يُستدعى عند رفع الإصبع أو عند الإرسال).
  Future<void> stopRecording() async {
    if (!isRecording.value) return;
    try {
      final path = await _recorder.stop();
      isRecording.value = false;
      if (path != null && path.isNotEmpty) {
        audioPath.value = path;
      }
    } catch (_) {
      isRecording.value = false;
    }
  }

  /// حذف التسجيل الحالي لتمكين تسجيل صوت جديد.
  Future<void> removeAudio() async {
    if (isRecording.value) {
      await stopRecording();
    }
    final path = audioPath.value;
    audioPath.value = null;
    errorMessage.value = null;
    if (path != null && path.isNotEmpty) {
      try {
        final file = File(path);
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
  }

  Future<String?> _uploadAudio() async {
    final path = audioPath.value;
    if (path == null || path.isEmpty) return null;
    final file = File(path);
    if (!await file.exists()) return null;
    final api = Get.find<AuthController>().apiClient;
    return api.uploadOrderNoteAudio(path);
  }

  /// إرسال الطلب الصوتي: إيقاف التسجيل إن كان جارياً، ثم رفع المقطع وإنشاء الطلب.
  /// [guestCredentials] إن وُجد، يُعرض دايلوج النجاح مع معلومات الحساب.
  Future<void> submit({GuestRegisterResult? guestCredentials}) async {
    errorMessage.value = null;
    if (isRecording.value) {
      await stopRecording();
    }
    if (audioPath.value == null || audioPath.value!.isEmpty) {
      AppToast.show('المقطع الصوتي', 'يرجى النقر على تسجيل ثم إرسال الطلب الصوتي', type: ToastType.warning);
      return;
    }
    if (!isVoiceOrderOnlyZone.value && selectedShops.isEmpty) {
      AppToast.show('المحلات', 'يرجى اختيار محل واحد على الأقل', type: ToastType.warning);
      return;
    }

    double? lng;
    double? lat;
    final user = Get.find<AuthController>().user.value;
    final loc = user?.location;
    if (loc is Map<String, dynamic> && loc['coordinates'] is List) {
      final coords = loc['coordinates'] as List;
      if (coords.length >= 2) {
        lng = (coords[0] as num).toDouble();
        lat = (coords[1] as num).toDouble();
      }
    }
    if (lng == null || lat == null) {
      DeliveryLocationRequiredDialog.show();
      return;
    }

    isSubmitting.value = true;
    try {
      isUploading.value = true;
      final notesAudioUrl = await _uploadAudio();
      isUploading.value = false;
      if (notesAudioUrl == null || notesAudioUrl.isEmpty) {
        errorMessage.value = 'فشل رفع المقطع الصوتي';
        isSubmitting.value = false;
        return;
      }
      final orders = <Order>[];
      if (isVoiceOrderOnlyZone.value) {
        final order = await OrderService.createVoiceOrderWithoutShop(
          lng: lng,
          lat: lat,
          notesAudioUrl: notesAudioUrl,
        );
        orders.add(order);
      } else {
        for (final shop in selectedShops) {
          final order = await OrderService.createVoiceOrder(
            shopId: shop.id,
            lng: lng,
            lat: lat,
            notesAudioUrl: notesAudioUrl,
          );
          orders.add(order);
        }
      }
      Get.back();
      if (guestCredentials != null) {
        showOrderSuccessWithCredentialsDialog(
          phone: guestCredentials.phone,
          code: guestCredentials.code,
          onClose: () {
            if (Get.isRegistered<OrdersController>()) {
              Get.find<OrdersController>().loadOrders();
            }
            try {
              final shell = Get.find<MainShellController>();
              shell.setTab(kTabOrders);
            } catch (_) {}
          },
        );
      } else {
        _showSuccessDialog(orders.length, isVoiceOrderOnly: isVoiceOrderOnlyZone.value);
      }
    } on ApiException catch (e) {
      isUploading.value = false;
      errorMessage.value = e.message;
      if (ZoneNotSupportedDialog.isZoneError(e)) {
        ZoneNotSupportedDialog.show();
      } else {
        AppToast.show('فشل الطلب', e.message, type: ToastType.error);
      }
    } catch (e) {
      isUploading.value = false;
      errorMessage.value = e.toString();
      AppToast.show('فشل الطلب', 'حدث خطأ، حاول مرة أخرى', type: ToastType.error);
    } finally {
      isSubmitting.value = false;
    }
  }

  void _showSuccessDialog(int orderCount, {bool isVoiceOrderOnly = false}) {
    final contentText = isVoiceOrderOnly
        ? 'تم إرسال الطلب الصوتي بنجاح. يمكنك متابعة حالة الطلب من صفحة الطلبات.'
        : orderCount == 1
            ? 'تم إرسال الطلب الصوتي بنجاح. يمكنك متابعة حالة الطلب من صفحة الطلبات.'
            : 'تم إرسال الطلب الصوتي إلى $orderCount محلات بنجاح. يمكنك متابعة الطلبات من صفحة الطلبات.';
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text(
          'تم إرسال طلبك بنجاح',
          style: TextStyle(
            fontFamily: kFontFamilyCairo,
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          contentText,
          style: TextStyle(
            fontFamily: kFontFamilyCairo,
            fontSize: 15.sp,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        contentPadding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 20.h),
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Get.back();
                if (Get.isRegistered<OrdersController>()) {
                  Get.find<OrdersController>().loadOrders();
                }
                try {
                  final shell = Get.find<MainShellController>();
                  shell.setTab(kTabOrders);
                } catch (_) {}
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                foregroundColor: AppColors.primaryLight,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
              ),
              child: Text(
                'متابعة الطلبات',
                style: TextStyle(
                  fontFamily: kFontFamilyCairo,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }
}
