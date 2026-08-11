import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Offset;
import 'package:get/get.dart';

import '../core/errors/api_exception.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../services/order_service.dart';
import '../widgets/common/app_toast.dart';
import '../widgets/dialogs/delivery_location_required_dialog.dart';
import '../widgets/dialogs/zone_not_supported_dialog.dart';
import 'auth_controller.dart';

/// Controller للسلة — إضافة، إزالة، تحديث الكمية، إتمام الطلب (مشترك مع الـ API).
class CartController extends GetxController {
  final RxList<CartItem> items = <CartItem>[].obs;

  /// حالة لوحة السلة الجانبية: مفتوحة أو مطوية (للتوافق مع StatelessWidget).
  final RxBool isCartPanelExpanded = false.obs;

  /// موضع زر السلة العائم (أعلى-يسار). null = الوضع الافتراضي (يمين، منتصف عمودي).
  final Rx<Offset?> floatingCartPosition = Rx<Offset?>(null);

  /// true أثناء السحب لتمييز السحب عن النقر.
  final RxBool floatingCartIsDragging = false.obs;

  void toggleCartPanel() => isCartPanelExpanded.toggle();

  /// يهيئ حالة السحب فقط (بدون تحديث الموضع لتجنب إعادة بناء الـ UI وإلغاء الجستشر).
  void startFloatingCartDrag(double screenWidth, double screenHeight, double tabWidth, double tabHeight) {
    floatingCartIsDragging.value = false;
  }

  /// يهيئ الموضع عند أول حركة سحب (يُستدعى من onPanUpdate عند وجود delta).
  void _ensureFloatingCartPosition(double screenWidth, double screenHeight, double tabWidth, double tabHeight) {
    if (floatingCartPosition.value == null) {
      floatingCartPosition.value = Offset(
        screenWidth - tabWidth,
        (screenHeight - tabHeight) / 2,
      );
    }
  }

  /// يطبق حركة السحب مع الإبقاء على الزر داخل الشاشة.
  void applyFloatingCartDrag(Offset delta, double screenWidth, double screenHeight, double tabWidth, double tabHeight) {
    if (delta.distance > 10) floatingCartIsDragging.value = true;
    _ensureFloatingCartPosition(screenWidth, screenHeight, tabWidth, tabHeight);
    final pos = floatingCartPosition.value!;
    floatingCartPosition.value = Offset(
      (pos.dx + delta.dx).clamp(0.0, screenWidth - tabWidth),
      (pos.dy + delta.dy).clamp(0.0, screenHeight - tabHeight),
    );
  }

  void endFloatingCartDrag() => floatingCartIsDragging.value = false;

  /// إضافة منتج للسلة. إن وُجد نفس المنتج تُزاد الكمية.
  void add(Product product, {int quantity = 1}) {
    if (quantity < 1) return;
    final key = _productKey(product);
    final index = items.indexWhere((e) => _productKey(e.product) == key);
    if (index >= 0) {
      final current = items[index];
      items[index] = CartItem(product: current.product, quantity: current.quantity + quantity);
    } else {
      items.add(CartItem(product: product, quantity: quantity));
    }
  }

  /// يتحقق إن كان المنتج موجوداً في السلة (بغض النظر عن الكمية).
  bool isInCart(Product product) {
    final key = _productKey(product);
    return items.any((e) => _productKey(e.product) == key);
  }

  /// يحذف منتجاً من السلة بالكامل (بغض النظر عن الكمية).
  void removeProduct(Product product) {
    final key = _productKey(product);
    final index = items.indexWhere((e) => _productKey(e.product) == key);
    if (index >= 0) {
      items.removeAt(index);
    }
  }

  void removeAt(int index) {
    if (index >= 0 && index < items.length) items.removeAt(index);
  }

  /// تحديث كمية عنصر. إن أصبحت 0 يُزال العنصر.
  void updateQuantity(int index, int quantity) {
    if (index < 0 || index >= items.length) return;
    if (quantity < 1) {
      items.removeAt(index);
      return;
    }
    final item = items[index];
    items[index] = CartItem(product: item.product, quantity: quantity);
  }

  /// المجموع الكلي لجميع عناصر السلة.
  double get totalPrice => items.fold(0.0, (sum, e) => sum + e.lineTotal);

  /// إجمالي عدد الوحدات (للعرض على الـ Badge).
  int get itemCount => items.fold(0, (sum, e) => sum + e.quantity);

  /// إتمام الطلب من السلة (مشترك: السلة الجانبية + شاشة السلة).
  /// يتطلب مصادقة. إحداثيات التوصيل من [lng]/[lat] أو من موقع المستخدم إن وُجد.
  /// [notes] ملاحظة كتابية، [notesAudioUrl] رابط ملاحظة صوتية (بعد رفع الملف).
  /// عند النجاح يُفرّغ السلة ويُرجع الطلب المُنشأ. عند الفشل يعرض رسالة ويُرجع null.
  Future<Order?> completeOrderFromCart({
    double? lng,
    double? lat,
    String? notes,
    String? notesAudioUrl,
  }) async {
    final auth = Get.find<AuthController>();
    if (!auth.isAuthenticated) {
      AppToast.show('تسجيل الدخول', 'يرجى تسجيل الدخول لإتمام الطلب', type: ToastType.warning);
      return null;
    }
    if (items.isEmpty) {
      AppToast.show('السلة فارغة', 'أضف منتجات قبل إتمام الطلب', type: ToastType.warning);
      return null;
    }
    if (lng == null || lat == null) {
      final user = auth.user.value;
      final loc = user?.location;
      if (loc is Map<String, dynamic> && loc['coordinates'] is List) {
        final coords = loc['coordinates'] as List;
        if (coords.length >= 2) {
          lng = (coords[0] as num).toDouble();
          lat = (coords[1] as num).toDouble();
        }
      }
    }
    if (lng == null || lat == null) {
      DeliveryLocationRequiredDialog.show();
      return null;
    }
    try {
      final order = await OrderService.createOrderFromCart(
        items: items.toList(),
        lng: lng,
        lat: lat,
        notes: notes,
        notesAudioUrl: notesAudioUrl,
      );
      items.clear();
      debugPrint('[CompleteOrder] نجاح: طلب واحد id=${order.id}, status=${order.status}');
      return order;
    } on ApiException catch (e) {
      debugPrint('[CompleteOrder] فشل API: ${e.message}');
      if (ZoneNotSupportedDialog.isZoneError(e)) {
        ZoneNotSupportedDialog.show();
      } else {
        AppToast.show('فشل الطلب', e.message, type: ToastType.error);
      }
      return null;
    } catch (e, st) {
      debugPrint('[CompleteOrder] خطأ: $e');
      debugPrint('[CompleteOrder] stackTrace: $st');
      AppToast.show('فشل الطلب', 'حدث خطأ، حاول مرة أخرى', type: ToastType.error);
      return null;
    }
  }

  String _productKey(Product p) {
    if (p.id != null && p.id!.isNotEmpty) return p.id!;
    return '${p.name}_${p.shopId ?? p.shopName ?? ""}';
  }
}
