import 'package:get/get.dart';

import '../core/api/api_exception.dart';
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

  late final Rx<ProductModel> currentProduct;
  final quantity = 1.obs;
  final selectedImageIndex = 0.obs;
  late final RxBool isFavorite;
  final isLoading = false.obs;
  /// أول تحميل للتفاصيل — يمنع وميض صورة واحدة ثم ظهور باقي الصور.
  final isHydratingDetail = false.obs;
  final loadError = RxnString();

  ProductModel get product => currentProduct.value;

  bool get showGalleryLoading =>
      isHydratingDetail.value && product.images.length <= 1;

  @override
  void onInit() {
    super.onInit();
    currentProduct = _initialProduct.obs;
    isFavorite = _favoritesService.isFavorite(_initialProduct.id).obs;
    loadProductDetail();
  }

  Future<void> loadProductDetail() async {
    final shopId = currentProduct.value.shopId?.trim() ?? '';
    final productId = currentProduct.value.id.trim();
    if (shopId.isEmpty || productId.isEmpty) return;

    final shouldHoldGallery = currentProduct.value.images.length <= 1;
    isLoading.value = true;
    if (shouldHoldGallery) {
      isHydratingDetail.value = true;
    }
    loadError.value = null;
    try {
      final fresh = await _shopService.fetchShopProduct(
        shopId: shopId,
        productId: productId,
        shopName: currentProduct.value.storeName,
      );
      currentProduct.value = _favoritesService
          .applyFavoriteState([fresh])
          .first;
      isFavorite.value = currentProduct.value.isFavorite;
      if (selectedImageIndex.value >= currentProduct.value.images.length) {
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
    final isFavoriteNow = await _favoritesService.toggle(currentProduct.value);
    isFavorite.value = isFavoriteNow;
    currentProduct.value = currentProduct.value.copyWith(
      isFavorite: isFavoriteNow,
    );
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
    final current = currentProduct.value;
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
