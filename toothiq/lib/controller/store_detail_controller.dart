import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../service_layer/services/preferences_storage.dart';
import '../utils/storage_keys.dart';
import '../core/api/api_exception.dart';
import '../core/utils/image_url.dart';
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
  final popularProducts = <ProductModel>[].obs;
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
  static const int _popularLimit = 10;

  static const tabs = [
    'المنتجات',
    'الأقسام',
    'التقييم',
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
  bool get hasLoadedStore => currentStore.value != null;

  @override
  void onInit() {
    super.onInit();
    loadStoreData();
    searchController.addListener(_onSearchChanged);
  }

  void _loadAboutInfo([StoreModel? source]) {
    final target = source ?? viewStore;
    final storage = PreferencesStorage.instance;
    final stored = storage.getString(StorageKeys.storeAbout(target.id)) ?? '';
    aboutDescription.value = stored.isNotEmpty &&
            stored != StoreModel.defaultAboutDescription
        ? stored
        : target.aboutDescription.trim();
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
      final shopName = store.name;
      late StoreModel updatedStore;
      late List<ShopCategoryModel> shopCategories;
      late List<StoreReviewModel> shopReviews;
      late ({List<ProductModel> items, bool hasNextPage, int page})
          productsPage;
      var loadedOffers = <ProductModel>[];
      var loadedPopular = <ProductModel>[];

      await Future.wait([
        _shopService.getShopById(storeId).then((value) => updatedStore = value),
        _shopService
            .fetchShopProductCategories(storeId, grouped: false)
            .then((value) => shopCategories = value),
        _shopService
            .fetchShopReviews(storeId)
            .then((value) => shopReviews = value),
        _shopService
            .fetchShopProductsPaginated(
              shopId: storeId,
              shopName: shopName,
              page: 1,
              limit: _productsPageSize,
            )
            .then((result) {
          productsPage = (
            items: result.items,
            hasNextPage: result.hasNextPage,
            page: result.page,
          );
        }),
        () async {
          try {
            final offersResult =
                await _shopService.fetchShopProductsPaginated(
              shopId: storeId,
              shopName: shopName,
              page: 1,
              limit: 10,
              hasOffer: true,
            );
            loadedOffers =
                _favoritesService.applyFavoriteState(offersResult.items);
          } catch (_) {
            loadedOffers = const [];
          }
        }(),
        () async {
          try {
            final popular = await _shopService.fetchShopBestSellers(
              shopId: storeId,
              shopName: shopName,
              limit: _popularLimit,
            );
            loadedPopular = _favoritesService.applyFavoriteState(popular);
          } catch (_) {
            loadedPopular = const [];
          }
        }(),
      ]);

      final loadedProducts =
          _favoritesService.applyFavoriteState(productsPage.items);
      final categoryCards = _mapCategories(shopCategories);
      final mappedBrands = await _shopService.fetchShopBrands(
        categoryIds: shopCategories
            .map((c) => c.parentCategoryId)
            .whereType<String>()
            .where((id) => id.isNotEmpty)
            .toSet()
            .toList(growable: false),
        products: loadedProducts,
        shopCategories: shopCategories,
      );

      var readyStore = updatedStore;
      if (readyStore.rating <= 0 && shopReviews.isNotEmpty) {
        final total = shopReviews.fold<int>(0, (sum, item) => sum + item.rating);
        readyStore = readyStore.copyWith(
          rating: total / shopReviews.length,
        );
      }

      await _precacheStoreVisuals(
        readyStore,
        [...loadedPopular, ...loadedOffers, ...loadedProducts],
      );

      products.assignAll(loadedProducts);
      hasNextProductsPage.value = productsPage.hasNextPage;
      currentProductsPage.value = productsPage.page;
      offerProducts.assignAll(loadedOffers);
      popularProducts.assignAll(loadedPopular);
      categories.assignAll(categoryCards);
      filteredCategories.assignAll(categoryCards);
      brands.assignAll(mappedBrands);
      filteredBrands.assignAll(mappedBrands);
      reviews.assignAll(shopReviews);
      _loadAboutInfo(readyStore);
      currentStore.value = readyStore;
    } on ApiException catch (error) {
      loadError.value = error.message;
      if (currentStore.value == null) {
        products.clear();
        offerProducts.clear();
        popularProducts.clear();
        categories.clear();
        filteredCategories.clear();
        brands.clear();
        filteredBrands.clear();
        reviews.clear();
        hasNextProductsPage.value = false;
      }
    } catch (_) {
      loadError.value = 'تعذر تحميل بيانات المتجر';
      if (currentStore.value == null) {
        products.clear();
        offerProducts.clear();
        popularProducts.clear();
        categories.clear();
        filteredCategories.clear();
        brands.clear();
        filteredBrands.clear();
        reviews.clear();
        hasNextProductsPage.value = false;
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _precacheStoreVisuals(
    StoreModel shop,
    List<ProductModel> items,
  ) async {
    await WidgetsBinding.instance.endOfFrame;
    final context = Get.overlayContext ?? Get.context;
    if (context == null) return;

    final sources = <String>{
      shop.logoAsset,
      ...items.take(8).map((item) => item.imageAsset),
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
    final source = ImageUrl.resolve(
      raw,
      fallback: StoreModel.defaultLogoAsset,
    );
    try {
      final ImageProvider provider = ImageUrl.isNetwork(source)
          ? NetworkImage(source)
          : AssetImage(source);
      await precacheImage(provider, context);
    } catch (_) {}
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
    final popularIdx = popularProducts.indexWhere((p) => p.id == productId);
    if (popularIdx != -1) {
      popularProducts[popularIdx] =
          popularProducts[popularIdx].copyWith(isFavorite: isFavorite);
      popularProducts.refresh();
    }
  }
}
