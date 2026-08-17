import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/api/api_exception.dart';
import '../core/utils/image_url.dart';
import '../model/product_model.dart';
import '../model/store_model.dart';
import '../bindings/checkout_binding.dart';
import '../service_layer/services/favorites_service.dart';
import '../service_layer/services/shop_service.dart';
import '../view/stores/store_detail_page.dart';
import '../widget/common/app_toast.dart';
import 'cart_controller.dart';
import 'checkout_controller.dart';

class ProductDetailsController extends GetxController {
  ProductDetailsController({required ProductModel product})
    : _initialProduct = product;

  final ProductModel _initialProduct;
  final ShopService _shopService = Get.find<ShopService>();
  final FavoritesService _favoritesService = Get.find<FavoritesService>();

  final currentProduct = Rxn<ProductModel>();
  final quantity = 1.obs;
  final selectedImageIndex = 0.obs;
  late final RxBool isFavorite;
  final isLoading = false.obs;
  final isHydratingDetail = false.obs;
  final loadError = RxnString();

  ProductModel get product => currentProduct.value ?? _initialProduct;
  bool get isReady => currentProduct.value != null;

  bool get showGalleryLoading =>
      isHydratingDetail.value && product.images.length <= 1;

  @override
  void onInit() {
    super.onInit();
    isFavorite = _favoritesService.isFavorite(_initialProduct.id).obs;
    loadProductDetail();
  }

  Future<void> loadProductDetail() async {
    final source = currentProduct.value ?? _initialProduct;
    final shopId = source.shopId?.trim() ?? '';
    final productId = source.id.trim();
    if (shopId.isEmpty || productId.isEmpty) {
      currentProduct.value = _initialProduct;
      return;
    }

    isLoading.value = true;
    if (currentProduct.value == null) {
      isHydratingDetail.value = true;
    }
    loadError.value = null;
    try {
      final fresh = await _shopService.fetchShopProduct(
        shopId: shopId,
        productId: productId,
        shopName: source.storeName,
      );
      final ready = _favoritesService.applyFavoriteState([fresh]).first;
      await _precacheProductImages(ready);
      currentProduct.value = ready;
      isFavorite.value = ready.isFavorite;
      if (selectedImageIndex.value >= ready.images.length) {
        selectedImageIndex.value = 0;
      }
    } on ApiException catch (error) {
      loadError.value = error.message;
    } catch (_) {
      loadError.value = 'تعذر تحميل بيانات المنتج';
    } finally {
      isLoading.value = false;
      isHydratingDetail.value = false;
    }
  }

  Future<void> _precacheProductImages(ProductModel item) async {
    await WidgetsBinding.instance.endOfFrame;
    final context = Get.overlayContext ?? Get.context;
    if (context == null) return;

    final sources = <String>{
      item.imageAsset,
      ...item.images.take(6),
    };
    await Future.wait(
      sources.map(
        (source) => _precacheSource(context, source).timeout(
          const Duration(milliseconds: 1800),
          onTimeout: () {},
        ),
      ),
    );
  }

  Future<void> _precacheSource(BuildContext context, String raw) async {
    final source = ImageUrl.resolve(raw);
    try {
      final ImageProvider provider = ImageUrl.isNetwork(source)
          ? NetworkImage(source)
          : AssetImage(source);
      await precacheImage(provider, context);
    } catch (_) {}
  }

  @override
  Future<void> refresh() async {
    await loadProductDetail();
  }

  void selectImage(int index) {
    selectedImageIndex.value = index;
  }

  void incrementQuantity() {
    quantity.value++;
  }

  void decrementQuantity() {
    if (quantity.value > 1) quantity.value--;
  }

  Future<void> toggleFavorite() async {
    final current = currentProduct.value;
    if (current == null) return;
    final isFavoriteNow = await _favoritesService.toggle(current);
    isFavorite.value = isFavoriteNow;
    currentProduct.value = current.copyWith(isFavorite: isFavoriteNow);
  }

  void addToCart() {
    final cart = Get.isRegistered<CartController>()
        ? Get.find<CartController>()
        : Get.put(CartController(), permanent: true);
    cart.addProduct(product, quantity: quantity.value);
  }

  void buyNow() {
    final cart = Get.isRegistered<CartController>()
        ? Get.find<CartController>()
        : Get.put(CartController(), permanent: true);
    cart
      ..clearCart()
      ..addProduct(product, quantity: quantity.value, showFeedback: false);

    CheckoutBinding().dependencies();
    Get.find<CheckoutController>().startCheckout();
  }

  void openStorePage() {
    final current = currentProduct.value ?? _initialProduct;
    final shopId = current.shopId?.trim() ?? '';
    if (shopId.isEmpty) {
      AppToast.show(
        'تعذر فتح المتجر',
        'معلومات المتجر غير مكتملة لهذا المنتج',
        type: ToastType.warning,
      );
      return;
    }

    final storeName = current.storeName.trim().isEmpty
        ? 'المتجر'
        : current.storeName.trim();
    StoreDetailPage.open(
      StoreModel(
        id: shopId,
        name: storeName,
        description: '',
      ),
    );
  }
}
