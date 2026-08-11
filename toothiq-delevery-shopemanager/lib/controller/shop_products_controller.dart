import 'package:get/get.dart';

import '../bindings/app_binding.dart';
import '../controller/session_controller.dart';
import '../core/utils/image_url.dart';
import '../model/shop_product.dart';
import '../service_layer/services/product_stock_cache.dart';
import '../service_layer/services/shop_service.dart';

class ShopProductsController extends GetxController {
  ShopProductsController({
    required ShopService shopService,
    required SessionController session,
    required ProductStockCache stockCache,
  }) : _shopService = shopService,
       _session = session,
       _stockCache = stockCache;

  final ShopService _shopService;
  final SessionController _session;
  final ProductStockCache _stockCache;

  final products = <ShopProduct>[].obs;
  final isSaving = false.obs;
  final isLoading = false.obs;
  final searchQuery = ''.obs;
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _stockCache.ensureLoaded().then((_) => loadProducts());
  }

  Future<void> loadProducts() async {
    final shopId = _session.shopId.value;
    if (shopId.isEmpty) return;

    isLoading.value = true;
    errorMessage.value = '';
    try {
      await _stockCache.ensureLoaded();
      final list = await _shopService.fetchProducts(shopId);
      products.assignAll(
        list.map((product) => _withResolvedImages(_mergeStock(product))),
      );
    } catch (error) {
      errorMessage.value = apiErrorMessage(error);
    } finally {
      isLoading.value = false;
    }
  }

  List<ShopProduct> get filteredProducts {
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return products;
    return products
        .where(
          (p) =>
              p.name.toLowerCase().contains(q) ||
              (p.categoryName?.toLowerCase().contains(q) ?? false) ||
              (p.brandName?.toLowerCase().contains(q) ?? false),
        )
        .toList();
  }

  int get availableCount => products.where((p) => p.isAvailable).length;

  Future<bool> addProduct({
    required String name,
    required String description,
    required int price,
    required int stock,
    String? imagePath,
    List<String> galleryPaths = const [],
    String? categoryId,
    String? categoryName,
    String? brandId,
    String? brandName,
    String? expiryDate,
    String? origin,
  }) async {
    final shopId = _session.shopId.value;
    if (shopId.isEmpty) return false;

    isSaving.value = true;
    try {
      final draft = ShopProduct(
        id: '',
        name: name,
        description: description,
        price: price,
        stock: stock,
        categoryId: categoryId,
        categoryName: categoryName,
        brandId: brandId,
        brandName: brandName,
        expiryDate: expiryDate,
        origin: origin,
      );
      final created = await _shopService.createProduct(
        shopId: shopId,
        product: draft,
        imagePath: imagePath,
        galleryPaths: galleryPaths,
      );
      await _stockCache.save(created.id, stock);
      final saved = _mergeStock(created.copyWith(stock: stock));
      products.insert(0, _withResolvedImages(saved));
      return true;
    } catch (error) {
      Get.snackbar('خطأ', apiErrorMessage(error));
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> updateProduct(ShopProduct product) async {
    final shopId = _session.shopId.value;
    if (shopId.isEmpty) return false;

    isSaving.value = true;
    try {
      await _stockCache.save(product.id, product.stock);
      final updated = await _shopService.updateProduct(
        shopId: shopId,
        product: product,
        imagePath: product.imagePath,
        galleryPaths: product.galleryPaths,
      );
      final index = products.indexWhere((p) => p.id == product.id);
      if (index >= 0) {
        products[index] = _withResolvedImages(_mergeStock(updated));
      }
      return true;
    } catch (error) {
      Get.snackbar('خطأ', apiErrorMessage(error));
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> toggleAvailability(String id) async {
    final shopId = _session.shopId.value;
    if (shopId.isEmpty) return;

    final index = products.indexWhere((p) => p.id == id);
    if (index < 0) return;

    final current = products[index];
    try {
      final updated = await _shopService.toggleAvailability(
        shopId: shopId,
        productId: id,
        isAvailable: !current.isAvailable,
      );
      products[index] = _withResolvedImages(_mergeStock(updated));
    } catch (error) {
      Get.snackbar('خطأ', apiErrorMessage(error));
    }
  }

  Future<void> removeProduct(String id) async {
    final shopId = _session.shopId.value;
    if (shopId.isEmpty) return;

    try {
      await _shopService.deleteProduct(shopId: shopId, productId: id);
      await _stockCache.remove(id);
      products.removeWhere((p) => p.id == id);
    } catch (error) {
      Get.snackbar('خطأ', apiErrorMessage(error));
    }
  }

  ShopProduct? findProduct(String id) {
    for (final product in products) {
      if (product.id == id) return product;
    }
    return null;
  }

  ShopProduct _mergeStock(ShopProduct product) {
    if (product.stock > 0) return product;
    final cached = _stockCache.get(product.id);
    if (cached != null && cached > 0) {
      return product.copyWith(stock: cached);
    }
    return product;
  }

  ShopProduct _withResolvedImages(ShopProduct product) {
    final image = product.imagePath;
    final resolvedImage = image == null || image.isEmpty || ImageUrl.isLocalFile(image)
        ? image
        : ImageUrl.resolve(image);
    final gallery = product.galleryPaths
        .map(
          (path) => ImageUrl.isLocalFile(path) ? path : ImageUrl.resolve(path),
        )
        .toList(growable: false);
    return product.copyWith(imagePath: resolvedImage, galleryPaths: gallery);
  }
}
