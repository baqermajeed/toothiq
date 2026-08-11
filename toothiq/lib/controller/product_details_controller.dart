import 'package:get/get.dart';

import '../core/api/api_exception.dart';
import '../model/product_model.dart';
import '../service_layer/services/shop_service.dart';
import 'cart_controller.dart';

class ProductDetailsController extends GetxController {
  ProductDetailsController({required ProductModel product})
    : _initialProduct = product;

  final ProductModel _initialProduct;
  final ShopService _shopService = Get.find<ShopService>();

  late final Rx<ProductModel> currentProduct;
  final quantity = 1.obs;
  final selectedImageIndex = 0.obs;
  late final RxBool isFavorite;
  final isLoading = false.obs;
  final loadError = RxnString();

  ProductModel get product => currentProduct.value;

  @override
  void onInit() {
    super.onInit();
    currentProduct = _initialProduct.obs;
    isFavorite = currentProduct.value.isFavorite.obs;
    loadProductDetail();
  }

  Future<void> loadProductDetail() async {
    final shopId = currentProduct.value.shopId?.trim() ?? '';
    final productId = currentProduct.value.id.trim();
    if (shopId.isEmpty || productId.isEmpty) return;

    isLoading.value = true;
    loadError.value = null;
    try {
      final fresh = await _shopService.fetchShopProduct(
        shopId: shopId,
        productId: productId,
        shopName: currentProduct.value.storeName,
      );
      currentProduct.value = fresh;
      isFavorite.value = fresh.isFavorite;
      selectedImageIndex.value = 0;
    } on ApiException catch (error) {
      loadError.value = error.message;
    } catch (_) {
      loadError.value = 'تعذر تحميل بيانات المنتج';
    } finally {
      isLoading.value = false;
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

  void toggleFavorite() {
    isFavorite.value = !isFavorite.value;
    currentProduct.value = currentProduct.value.copyWith(
      isFavorite: isFavorite.value,
    );
  }

  void addToCart() {
    final cart = Get.isRegistered<CartController>()
        ? Get.find<CartController>()
        : Get.put(CartController(), permanent: true);
    cart.addProduct(product, quantity: quantity.value);
  }

  void buyNow() {
    // TODO: شراء مباشر
  }
}
