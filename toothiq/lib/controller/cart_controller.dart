import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../core/api/api_exception.dart';
import '../model/cart_item_model.dart';
import '../model/product_model.dart';
import '../service_layer/services/order_service.dart';
import '../service_layer/services/platform_settings_service.dart';
import '../service_layer/services/preferences_storage.dart';
import '../utils/storage_keys.dart';
import '../widget/common/app_toast.dart';
import 'session_controller.dart';

class CartController extends GetxController {
  static const String _guestScope = '__guest__';

  final items = <CartItemModel>[].obs;
  final PreferencesStorage _prefs = PreferencesStorage.instance;
  String? _userId;

  PlatformSettingsService get _platformSettings =>
      Get.find<PlatformSettingsService>();

  bool get isEmpty => items.isEmpty;

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  int get orderSubtotal => items.fold(0, (sum, item) => sum + item.lineTotal);

  int get deliveryFeeAmount => _platformSettings.globalDeliveryFee;

  int get orderTotal => orderSubtotal + deliveryFeeAmount;

  @override
  void onInit() {
    super.onInit();
    _bindInitialScope();
  }

  Future<void> _bindInitialScope() async {
    if (!Get.isRegistered<SessionController>()) {
      await bindToUser(null);
      return;
    }
    final sessionUser = Get.find<SessionController>().user.value;
    await bindToUser(sessionUser?.id);
  }

  String formatPrice(int amount) {
    final formatted = amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '$formatted د.ع';
  }

  String get formattedOrderPrice => formatPrice(orderSubtotal);

  String get formattedDeliveryFee => _platformSettings.formattedDeliveryFee;

  String get formattedTotalPrice => formatPrice(orderTotal);

  void addProduct(
    ProductModel product, {
    int quantity = 1,
    bool showFeedback = true,
  }) {
    final index = items.indexWhere((e) => e.product.id == product.id);
    if (index >= 0) {
      items[index].quantity += quantity;
    } else {
      items.add(CartItemModel(product: product, quantity: quantity));
    }
    items.refresh();
    unawaited(_persist());

    if (!showFeedback) return;
    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }
    AppToast.show(
      'تمت إضافة المنتج إلى السلة',
      '',
      type: ToastType.success,
      duration: const Duration(milliseconds: 1200),
    );
  }

  void incrementQuantity(String productId) {
    final index = items.indexWhere((e) => e.product.id == productId);
    if (index == -1) return;
    items[index].quantity++;
    items.refresh();
    unawaited(_persist());
  }

  void decrementQuantity(String productId) {
    final index = items.indexWhere((e) => e.product.id == productId);
    if (index == -1) return;
    if (items[index].quantity > 1) {
      items[index].quantity--;
      items.refresh();
      unawaited(_persist());
    }
  }

  void removeItem(String productId) {
    items.removeWhere((e) => e.product.id == productId);
    items.refresh();
    unawaited(_persist());
  }

  void clearCart() {
    if (items.isEmpty) return;
    items.clear();
    items.refresh();
    unawaited(_persist());
  }

  void completePurchase() {
    if (isEmpty) return;
    // يُستدعى من BasketPage عبر CheckoutController.startCheckout()
  }

  bool get hasDeliveryCoordinates {
    final user = Get.find<SessionController>().user.value;
    return user != null && user.hasLocation;
  }

  /// نفس نهج قريب: فحص الجلسة والموقع ثم إرسال الطلب.
  Future<String> completeOrderFromCart({
    required String deliveryAddress,
    String? notes,
    double? lng,
    double? lat,
    bool clearAfterSuccess = true,
  }) async {
    if (!Get.find<SessionController>().isAuthenticated) {
      throw const ApiException('يرجى تسجيل الدخول لإتمام الطلب');
    }
    if (items.isEmpty) {
      throw const ApiException('السلة فارغة');
    }

    final address = deliveryAddress.trim();
    if (address.isEmpty) {
      throw const ApiException('يرجى تحديد عنوان التوصيل');
    }

    if (lng == null || lat == null) {
      final user = Get.find<SessionController>().user.value;
      if (user != null && user.hasLocation) {
        lng = user.locationLng;
        lat = user.locationLat;
      }
    }
    if (lng == null || lat == null) {
      throw const ApiException('يرجى تحديد موقع التوصيل على الخريطة');
    }

    try {
      final orderId = await Get.find<OrderService>().createOrderFromCart(
        items: items.toList(growable: false),
        deliveryAddress: address,
        deliveryCoordinates: [lng, lat],
        notes: notes,
      );
      if (orderId == null || orderId.isEmpty) {
        throw const ApiException('تعذر إنشاء الطلب');
      }
      if (clearAfterSuccess) {
        items.clear();
        items.refresh();
        await _persist();
      }
      return orderId;
    } on ApiException {
      rethrow;
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('[CompleteOrder] خطأ: $error');
        debugPrint('[CompleteOrder] stackTrace: $stackTrace');
      }
      throw const ApiException('حدث خطأ، حاول مرة أخرى');
    }
  }

  Future<void> bindToUser(String? userId) async {
    _userId = userId?.trim().isEmpty == true ? null : userId?.trim();
    items.clear();

    final raw = _prefs.getJsonList(StorageKeys.cartItemsFor(_scopeKey));
    if (raw == null || raw.isEmpty) {
      if (_userId == null) {
        final legacy = _prefs.getJsonList(StorageKeys.cartItems);
        if (legacy != null && legacy.isNotEmpty) {
          _loadItems(legacy);
        }
      }
      return;
    }
    _loadItems(raw);
  }

  String get _scopeKey => _userId ?? _guestScope;

  void _loadItems(List<Map<String, dynamic>> raw) {
    final loaded = raw
        .map(CartItemModel.fromJson)
        .where((item) => item.product.id.trim().isNotEmpty && item.quantity > 0)
        .toList(growable: false);
    items.assignAll(loaded);
  }

  Future<void> _persist() async {
    await _prefs.setJsonList(
      StorageKeys.cartItemsFor(_scopeKey),
      items.map((item) => item.toJson()).toList(growable: false),
    );

    if (_userId == null) {
      await _prefs.setJsonList(
        StorageKeys.cartItems,
        items.map((item) => item.toJson()).toList(growable: false),
      );
    }
  }
}
