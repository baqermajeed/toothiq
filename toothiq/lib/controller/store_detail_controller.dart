import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../service_layer/services/preferences_storage.dart';
import '../utils/storage_keys.dart';
import '../core/api/api_exception.dart';
import '../model/brand_model.dart';
import '../model/category_model.dart';
import '../model/product_model.dart';
import '../model/shop_category_model.dart';
import '../model/store_model.dart';
import '../model/store_review_model.dart';
import '../service_layer/services/favorites_service.dart';
import '../service_layer/services/shop_service.dart';
import '../view/auth/login_page.dart';
import '../widget/common/app_toast.dart';
import '../view/section/section_detail_page.dart';
import 'session_controller.dart';

class StoreDetailController extends GetxController {
  final ShopService _shopService = Get.find<ShopService>();
  final FavoritesService _favoritesService = Get.find<FavoritesService>();
  final StoreModel store;

  StoreDetailController({required this.store});

  final currentStore = Rxn<StoreModel>();
  final searchController = TextEditingController();
  final reviewController = TextEditingController();
  final selectedTabIndex = 0.obs;
  final searchQuery = ''.obs;
  final products = <ProductModel>[].obs;
  final offerProducts = <ProductModel>[].obs;
  final categories = <CategoryModel>[].obs;
  final filteredCategories = <CategoryModel>[].obs;
  final filteredBrands = <BrandModel>[].obs;
  final brands = <BrandModel>[].obs;
  final reviews = <StoreReviewModel>[].obs;
  final aboutDescription = ''.obs;
  final isLoading = false.obs;
  final loadingMoreProducts = false.obs;
  final hasNextProductsPage = false.obs;
  final currentProductsPage = 1.obs;
  final loadError = RxnString();
  final isSubmittingReview = false.obs;
  static const int _productsPageSize = 20;

  static const tabs = [
    'المنتجات',
    'الأقسام',
    'تقييم المتجر',
    'عن المتجر',
  ];

  static const _icons = <IconData>[
    Icons.brush_outlined,
    Icons.grid_view_rounded,
    Icons.healing_outlined,
    Icons.medical_services_outlined,
    Icons.construction_outlined,
    Icons.water_drop_outlined,
  ];
  static const _iconColors = <Color>[
    Color(0xFF26A69A),
    Color(0xFF00897B),
    Color(0xFF00796B),
    Color(0xFF00695C),
    Color(0xFF26A69A),
    Color(0xFF00897B),
  ];

  StoreModel get viewStore => currentStore.value ?? store;

  @override
  void onInit() {
    super.onInit();
    currentStore.value = store;
    loadStoreData();
    searchController.addListener(_onSearchChanged);
  }

  void _loadAboutInfo([StoreModel? source]) {
    final target = source ?? viewStore;
    final storage = PreferencesStorage.instance;
    aboutDescription.value =
        storage.getString(StorageKeys.storeAbout(target.id)) ??
        target.aboutDescription;
  }

  void _onSearchChanged() {
    searchQuery.value = searchController.text;
    final query = searchQuery.value.trim();

    switch (selectedTabIndex.value) {
      case 1:
        if (query.isEmpty) {
          filteredCategories.assignAll(categories);
        } else {
          filteredCategories.assignAll(
            categories.where((c) => c.name.contains(query)).toList(),
          );
        }
        break;
      default:
        break;
    }
  }

  List<ProductModel> get filteredProducts {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return products;
    return products
        .where(
          (p) =>
              p.name.toLowerCase().contains(query) ||
              p.description.toLowerCase().contains(query) ||
              p.storeName.toLowerCase().contains(query),
        )
        .toList();
  }

  List<ProductModel> get popularProducts => filteredProducts.take(4).toList();

  @override
  void onClose() {
    searchController.dispose();
    reviewController.dispose();
    super.onClose();
  }

  void selectTab(int index) {
    selectedTabIndex.value = index;
    _onSearchChanged();
  }

  void onCategoryTap(CategoryModel category) {
    SectionDetailPage.open(
      category,
      shopId: viewStore.id,
      shopName: viewStore.name,
    );
  }

  Future<void> loadStoreData() async {
    isLoading.value = true;
    loadError.value = null;
    try {
      final storeId = store.id;
      final results = await Future.wait([
        _shopService.getShopById(storeId),
        _shopService.fetchShopProductCategories(storeId, grouped: false),
        _shopService.fetchShopReviews(storeId),
      ]);

      final updatedStore = results[0] as StoreModel;
      currentStore.value = updatedStore;
      await _loadProductsFirstPage();
      await _loadOfferProducts();

      final shopCategories = results[1] as List<ShopCategoryModel>;
      final categoryCards = _mapCategories(shopCategories);
      categories.assignAll(categoryCards);
      filteredCategories.assignAll(categoryCards);

      final mappedBrands = await _shopService.fetchShopBrands(
        categoryIds: shopCategories
            .map((c) => c.parentCategoryId)
            .whereType<String>()
            .where((id) => id.isNotEmpty)
            .toSet()
            .toList(growable: false),
        products: products,
        shopCategories: shopCategories,
      );
      brands.assignAll(mappedBrands);
      filteredBrands.assignAll(mappedBrands);

      reviews.assignAll(results[2] as List<StoreReviewModel>);
      _loadAboutInfo(updatedStore);
    } on ApiException catch (error) {
      loadError.value = error.message;
      products.clear();
      offerProducts.clear();
      categories.clear();
      filteredCategories.clear();
      brands.clear();
      filteredBrands.clear();
      reviews.clear();
      hasNextProductsPage.value = false;
    } catch (_) {
      loadError.value = 'تعذر تحميل بيانات المتجر';
      products.clear();
      offerProducts.clear();
      categories.clear();
      filteredCategories.clear();
      brands.clear();
      filteredBrands.clear();
      reviews.clear();
      hasNextProductsPage.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadProductsFirstPage() async {
    currentProductsPage.value = 1;
    final result = await _shopService.fetchShopProductsPaginated(
      shopId: store.id,
      shopName: store.name,
      page: 1,
      limit: _productsPageSize,
    );
    products.assignAll(_favoritesService.applyFavoriteState(result.items));
    hasNextProductsPage.value = result.hasNextPage;
    currentProductsPage.value = result.page;
  }

  Future<void> _loadOfferProducts() async {
    try {
      final result = await _shopService.fetchShopProductsPaginated(
        shopId: store.id,
        shopName: store.name,
        page: 1,
        limit: 10,
        hasOffer: true,
      );
      offerProducts.assignAll(
        _favoritesService.applyFavoriteState(result.items),
      );
    } catch (_) {
      offerProducts.clear();
    }
  }

  Future<void> loadMoreProducts() async {
    if (loadingMoreProducts.value || !hasNextProductsPage.value) return;
    loadingMoreProducts.value = true;
    try {
      final nextPage = currentProductsPage.value + 1;
      final result = await _shopService.fetchShopProductsPaginated(
        shopId: store.id,
        shopName: store.name,
        page: nextPage,
        limit: _productsPageSize,
      );
      products.addAll(result.items);
      hasNextProductsPage.value = result.hasNextPage;
      currentProductsPage.value = result.page;
    } catch (_) {
      // لا نعرض خطأ لجلب المزيد.
    } finally {
      loadingMoreProducts.value = false;
    }
  }

  @override
  Future<void> refresh() async {
    await loadStoreData();
  }

  List<CategoryModel> _mapCategories(List<ShopCategoryModel> apiCategories) {
    return apiCategories
        .asMap()
        .entries
        .map((entry) {
          final idx = entry.key;
          final item = entry.value;
          return CategoryModel(
            id: item.id,
            name: item.nameAr,
            iconUrl: item.iconUrl,
            icon: _icons[idx % _icons.length],
            iconColor: _iconColors[idx % _iconColors.length],
            source: item.isShopCategory && item.parentCategoryId == null
                ? CategorySource.shop
                : CategorySource.admin,
            shopId: store.id,
            productCategoryId: item.id,
            parentCategoryId: item.parentCategoryId,
          );
        })
        .toList(growable: false);
  }

  Future<void> submitReview() async {
    final text = reviewController.text.trim();
    if (text.isEmpty) return;
    if (isSubmittingReview.value) return;

    if (!Get.find<SessionController>().isAuthenticated) {
      AppToast.show(
        'تسجيل الدخول مطلوب',
        'يجب تسجيل الدخول لإرسال تقييمك',
        type: ToastType.warning,
      );
      await Get.to(() => const LoginPage());
      return;
    }

    isSubmittingReview.value = true;
    try {
      await _shopService.submitShopReview(
        shopId: viewStore.id,
        rating: 5,
        comment: text,
      );
      reviewController.clear();
      final latest = await _shopService.fetchShopReviews(viewStore.id);
      reviews.assignAll(latest);
      final updatedStore = await _shopService.getShopById(viewStore.id);
      currentStore.value = updatedStore;
      AppToast.show(
        'تم الإرسال',
        'شكراً لمشاركة رأيك',
        type: ToastType.success,
      );
    } on ApiException catch (error) {
      final message = error.statusCode == 401
          ? 'انتهت جلستك، سجّل الدخول ثم حاول مرة أخرى'
          : error.message;
      AppToast.show(
        'تعذر الإرسال',
        message,
        type: ToastType.error,
      );
    } catch (_) {
      AppToast.show(
        'تعذر الإرسال',
        'لم نتمكن من إرسال تقييمك حالياً',
        type: ToastType.error,
      );
    } finally {
      isSubmittingReview.value = false;
    }
  }

  Future<void> toggleFavorite(String productId) async {
    final idx = products.indexWhere((p) => p.id == productId);
    if (idx == -1) return;
    final isFavorite = await _favoritesService.toggle(products[idx]);
    products[idx] = products[idx].copyWith(isFavorite: isFavorite);
    products.refresh();
  }

  void updateFavoriteState(String productId, bool isFavorite) {
    final idx = products.indexWhere((p) => p.id == productId);
    if (idx != -1) {
      products[idx] = products[idx].copyWith(isFavorite: isFavorite);
      products.refresh();
    }
    final offerIdx = offerProducts.indexWhere((p) => p.id == productId);
    if (offerIdx != -1) {
      offerProducts[offerIdx] =
          offerProducts[offerIdx].copyWith(isFavorite: isFavorite);
      offerProducts.refresh();
    }
  }
}
