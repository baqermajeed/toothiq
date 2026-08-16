import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../model/app_contact_model.dart';
import '../../model/app_version_check_result.dart';
import '../../model/auth_session_model.dart';
import '../../model/banner_model.dart';
import '../../model/brand_model.dart';
import '../../model/category_section_model.dart';
import '../../model/driver_review_model.dart';
import '../../model/governorate_model.dart';
import '../../model/notification_model.dart';
import '../../model/order_detail_model.dart';
import '../../model/order_model.dart';
import '../../model/paginated_result.dart';
import '../../model/product_model.dart';
import '../../model/shop_category_model.dart';
import '../../model/store_model.dart';
import '../../model/store_review_model.dart';
import '../../model/user_model.dart';
import '../../service_layer/services/token_storage.dart';
import 'api_config.dart';
import 'api_endpoints.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({
    required TokenStorage tokenStorage,
    AsyncCallback? onSessionExpired,
  }) : _tokenStorage = tokenStorage,
       _onSessionExpired = onSessionExpired {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(onRequest: _onRequest, onError: _onError),
    );
  }

  final TokenStorage _tokenStorage;
  final AsyncCallback? _onSessionExpired;
  late final Dio _dio;

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final path = options.path;
    final isAuthPublic =
        path.contains('/auth/register') ||
        path.contains('/auth/login') ||
        path.contains('/auth/guest-register') ||
        path.contains('/auth/refresh');

    if (!isAuthPublic) {
      final token = await _tokenStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    if (error.response?.statusCode == 401) {
      await _tokenStorage.clearTokens();
      if (_onSessionExpired != null) {
        await _onSessionExpired();
      }
    }
    handler.next(error);
  }

  Future<AuthSessionModel> login({
    required String phone,
    required String password,
  }) async {
    final data = await _postSuccessData(
      ApiEndpoints.login,
      body: {'phone': phone, 'password': password},
    );
    if (data is! Map<String, dynamic>) {
      throw const ApiException('رد تسجيل الدخول غير صالح');
    }
    return AuthSessionModel.fromJson(data);
  }

  Future<AuthSessionModel> register({
    required String name,
    required String phone,
    required String governorateId,
    required String password,
    String? clinicName,
  }) async {
    final data = await _postSuccessData(
      ApiEndpoints.register,
      body: {
        'name': name,
        'phone': phone,
        'governorateId': governorateId,
        'password': password,
        if (clinicName != null && clinicName.trim().isNotEmpty)
          'clinicName': clinicName.trim(),
      },
    );
    if (data is! Map<String, dynamic>) {
      throw const ApiException('رد إنشاء الحساب غير صالح');
    }
    return AuthSessionModel.fromJson(data);
  }

  Future<void> logout() async {
    await _postExpectSuccess(ApiEndpoints.logout);
  }

  Future<AuthSessionModel> refresh(String refreshToken) async {
    final data = await _postSuccessData(
      ApiEndpoints.refresh,
      body: {'refreshToken': refreshToken},
    );
    if (data is! Map<String, dynamic>) {
      throw const ApiException('رد تحديث الجلسة غير صالح');
    }
    return AuthSessionModel.fromJson(data);
  }

  Future<UserModel> getMe() async {
    final data = await _getSuccessData(ApiEndpoints.currentUser);
    if (data is! Map<String, dynamic>) {
      throw const ApiException('رد بيانات المستخدم غير صالح');
    }
    return UserModel.fromJson(data);
  }

  Future<UserModel> updateMe({
    String? name,
    String? clinicName,
    List<double>? location,
  }) async {
    final data = await _patchSuccessData(
      ApiEndpoints.currentUser,
      body: {
        if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
        if (clinicName != null) 'clinicName': clinicName.trim(),
        if (location != null && location.length >= 2)
          'location': {
            'type': 'Point',
            'coordinates': [location[0], location[1]],
          },
      },
    );
    if (data is! Map<String, dynamic>) {
      throw const ApiException('رد تحديث بيانات المستخدم غير صالح');
    }
    return UserModel.fromJson(data);
  }

  /// تحديث توكن FCM للمستخدم الحالي (مثل قريب).
  Future<void> updateFcmToken(String? token) async {
    try {
      await _patchSuccessData(
        ApiEndpoints.currentUser,
        body: {'fcmToken': token},
      );
    } catch (_) {
      // لا نفشل التطبيق عند فشل تحديث التوكن
    }
  }

  /// قائمة إشعارات المستخدم من السيرفر.
  Future<({List<AppNotificationModel> items, int unreadCount})>
      getNotifications({int limit = 50}) async {
    final data = await _getSuccessData(
      ApiEndpoints.notifications,
      queryParameters: {'limit': limit},
    );
    if (data is! Map<String, dynamic>) {
      return (items: <AppNotificationModel>[], unreadCount: 0);
    }
    final rawItems = data['items'];
    final items = <AppNotificationModel>[];
    if (rawItems is List) {
      for (final entry in rawItems.whereType<Map<String, dynamic>>()) {
        items.add(AppNotificationModel.fromApiJson(entry));
      }
    }
    final unread = (data['unreadCount'] as num?)?.toInt() ??
        items.where((n) => !n.isRead).length;
    return (items: items, unreadCount: unread);
  }

  Future<int> getNotificationsUnreadCount() async {
    try {
      final data = await _getSuccessData(ApiEndpoints.notificationsUnreadCount);
      if (data is Map<String, dynamic>) {
        return (data['unreadCount'] as num?)?.toInt() ?? 0;
      }
    } catch (_) {}
    return 0;
  }

  Future<void> markAllNotificationsRead() async {
    try {
      await _patchSuccessData(ApiEndpoints.notificationsReadAll);
    } catch (_) {}
  }

  Future<void> markNotificationRead(String id) async {
    if (id.trim().isEmpty) return;
    try {
      await _patchSuccessData(ApiEndpoints.notificationRead(id));
    } catch (_) {}
  }

  /// التحقق من إصدار التطبيق — عام، لا يحتاج مصادقة.
  Future<AppVersionCheckResult?> getAppVersionCheck(String currentVersion) async {
    try {
      final response = await _dio.get(
        '${ApiEndpoints.appVersion}/check',
        queryParameters: {'version': currentVersion},
      );
      final data = response.data;
      if (data is! Map<String, dynamic> || data['success'] != true) return null;
      final payload = data['data'];
      if (payload is! Map<String, dynamic>) return null;
      return AppVersionCheckResult.fromJson(payload);
    } on DioException {
      return null;
    }
  }

  /// إعدادات المنصة العامة (تواصل، رسوم التوصيل، حالة التوصيل).
  Future<AppContactModel> getAppContact() async {
    try {
      final data = await _getSuccessData(ApiEndpoints.appContact);
      if (data is! Map<String, dynamic>) return AppContactModel.empty;
      return AppContactModel.fromJson(data);
    } catch (_) {
      return AppContactModel.empty;
    }
  }

  /// fallback لقراءة رسوم التوصيل من إعدادات المنصة (إذا كانت app-contact لا ترجعها).
  Future<Map<String, dynamic>?> getAdminSettings() async {
    try {
      final data = await _getSuccessData('/api/admin/settings');
      if (data is Map<String, dynamic>) return data;
      return null;
    } on ApiException catch (error) {
      if (error.statusCode == 401 ||
          error.statusCode == 403 ||
          error.statusCode == 404) {
        return null;
      }
      rethrow;
    } catch (_) {
      return null;
    }
  }

  Future<List<GovernorateModel>> getGovernorates() async {
    final data = await _getSuccessData(ApiEndpoints.governorates);
    if (data is! List) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(GovernorateModel.fromJson)
        .toList(growable: false);
  }

  Future<List<BannerModel>> getBanners() async {
    final data = await _getSuccessData(ApiEndpoints.banners);
    if (data is! List) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(BannerModel.fromJson)
        .toList(growable: false);
  }

  Future<List<ShopCategoryModel>> getCategories() async {
    final data = await _getSuccessData(ApiEndpoints.categories);
    if (data is! List) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(ShopCategoryModel.fromJson)
        .toList(growable: false);
  }

  /// أقسام الكتالوج الرئيسية — `GET /api/catalog/categories`.
  Future<List<ShopCategoryModel>> getCatalogCategories({bool tree = false}) async {
    final data = await _getSuccessData(
      ApiEndpoints.catalogCategories,
      queryParameters: {if (tree) 'tree': true},
    );
    if (data is! List) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(ShopCategoryModel.fromJson)
        .toList(growable: false);
  }

  /// تفاصيل قسم: أقسام فرعية + براندات — `GET /api/catalog/categories/{id}`.
  Future<ShopCategoryModel?> getCatalogCategoryById(String categoryId) async {
    if (categoryId.trim().isEmpty) return null;
    try {
      final data = await _getSuccessData(
        ApiEndpoints.catalogCategory(categoryId),
      );
      if (data is! Map<String, dynamic>) return null;
      return ShopCategoryModel.fromJson(data);
    } on ApiException catch (error) {
      if (error.statusCode == 404) return null;
      rethrow;
    }
  }

  /// أقسام فرعية لقسم — `GET /api/catalog/categories/{id}/subcategories`.
  Future<List<CategorySectionModel>> getCatalogSubcategories(
    String categoryId, {
    bool withCounts = true,
  }) async {
    if (categoryId.trim().isEmpty) return [];
    try {
      final data = await _getSuccessData(
        ApiEndpoints.catalogCategorySubcategories(categoryId),
        queryParameters: {if (withCounts) 'withCounts': true},
      );
      if (data is! List) return [];
      return data
          .whereType<Map<String, dynamic>>()
          .map(CategorySectionModel.fromJson)
          .where((section) => section.id.isNotEmpty && section.nameAr.isNotEmpty)
          .toList(growable: false);
    } on ApiException catch (error) {
      if (error.statusCode == 404) return [];
      rethrow;
    }
  }

  /// براندات لقسم — `GET /api/catalog/categories/{id}/brands`.
  Future<List<BrandModel>> getCatalogBrands(
    String categoryId, {
    bool withCounts = true,
  }) async {
    if (categoryId.trim().isEmpty) return [];
    try {
      final data = await _getSuccessData(
        ApiEndpoints.catalogCategoryBrands(categoryId),
        queryParameters: {if (withCounts) 'withCounts': true},
      );
      if (data is! List) return [];
      return data
          .whereType<Map<String, dynamic>>()
          .map(BrandModel.fromJson)
          .where((brand) => brand.id.isNotEmpty && brand.name.isNotEmpty)
          .toList(growable: false);
    } on ApiException catch (error) {
      if (error.statusCode == 404) return [];
      rethrow;
    }
  }

  Future<List<BrandModel>> getBrands({String? categoryId, String? shopId}) async {
    try {
      final data = await _getSuccessData(
        ApiEndpoints.brands,
        queryParameters: {
          if (categoryId != null && categoryId.isNotEmpty)
            'categoryId': categoryId,
          if (shopId != null && shopId.isNotEmpty) 'shopId': shopId,
        },
      );
      if (data is! List) return [];
      return data
          .whereType<Map<String, dynamic>>()
          .map(BrandModel.fromJson)
          .where((brand) => brand.id.isNotEmpty && brand.name.isNotEmpty)
          .toList(growable: false);
    } on ApiException catch (error) {
      if (error.statusCode == 404) return [];
      rethrow;
    }
  }

  Future<List<ProductModel>> getRandomProducts({
    String? productCategoryId,
    int shopCount = 6,
    int perShop = 2,
  }) async {
    final data = await _getSuccessData(
      ApiEndpoints.randomProducts,
      queryParameters: {
        'shopCount': shopCount,
        'perShop': perShop,
        if (productCategoryId != null && productCategoryId.isNotEmpty)
          'categoryId': productCategoryId,
      },
    );
    if (data is! Map<String, dynamic>) return [];
    final items = data['items'];
    if (items is! List) return [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(ProductModel.fromJson)
        .toList(growable: false);
  }

  Future<PaginatedResult<ProductModel>> getProducts({
    int page = 1,
    int limit = 12,
    String? productCategoryId,
    String? categoryId,
    String? brandId,
    bool hasOffer = false,
  }) async {
    final data = await _getSuccessData(
      ApiEndpoints.products,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (productCategoryId != null && productCategoryId.isNotEmpty)
          'productCategoryId': productCategoryId,
        if (categoryId != null && categoryId.isNotEmpty) 'categoryId': categoryId,
        if (brandId != null && brandId.isNotEmpty) 'brandId': brandId,
        if (hasOffer) 'hasOffer': true,
      },
    );
    return _parseProductsPaginatedData(data, page: page, limit: limit);
  }

  Future<PaginatedResult<ProductModel>> searchProducts(
    String query, {
    int page = 1,
    int limit = 12,
  }) async {
    final q = query.trim();
    final data = await _getSuccessData(
      ApiEndpoints.productSearch,
      queryParameters: {'q': q, 'page': page, 'limit': limit},
    );
    return _parseProductsPaginatedData(data, page: page, limit: limit);
  }

  Future<List<StoreModel>> getShops({
    String? category,
    int page = 1,
    int limit = 20,
  }) async {
    final data = await _getSuccessData(
      ApiEndpoints.shops,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (category != null && category.isNotEmpty) 'category': category,
      },
    );
    if (data is! Map<String, dynamic>) return [];
    final items = data['items'];
    if (items is! List) return [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(StoreModel.fromJson)
        .toList(growable: false);
  }

  Future<StoreModel> getShopById(String shopId) async {
    final data = await _getSuccessData(ApiEndpoints.shop(shopId));
    if (data is! Map<String, dynamic>) {
      throw const ApiException('رد بيانات المتجر غير صالح');
    }
    return StoreModel.fromJson(data);
  }

  Future<ProductModel> getShopProduct({
    required String shopId,
    required String productId,
    required String shopName,
  }) async {
    final data = await _getSuccessData(
      ApiEndpoints.shopProduct(shopId, productId),
    );
    if (data is! Map<String, dynamic>) {
      throw const ApiException('رد بيانات المنتج غير صالح');
    }
    return ProductModel.fromShopJson(data, shopId: shopId, shopName: shopName);
  }

  Future<List<ProductModel>> getShopProducts({
    required String shopId,
    required String shopName,
  }) async {
    final data = await _getSuccessData(ApiEndpoints.shopProducts(shopId));
    final items = (data is List)
        ? data
        : (data is Map<String, dynamic> ? data['items'] : null);
    if (items is! List) return [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => ProductModel.fromShopJson(
            item,
            shopId: shopId,
            shopName: shopName,
          ),
        )
        .toList(growable: false);
  }

  Future<PaginatedResult<ProductModel>> getShopProductsPaginated({
    required String shopId,
    required String shopName,
    int page = 1,
    int limit = 20,
    String? productCategoryId,
    String? categoryId,
    bool hasOffer = false,
  }) async {
    final data = await _getSuccessData(
      ApiEndpoints.shopProducts(shopId),
      queryParameters: {
        'page': page,
        'limit': limit,
        if (productCategoryId != null && productCategoryId.isNotEmpty)
          'productCategoryId': productCategoryId,
        if (categoryId != null && categoryId.isNotEmpty) 'categoryId': categoryId,
        if (hasOffer) 'hasOffer': true,
      },
    );
    if (data is! Map<String, dynamic>) {
      return PaginatedResult(items: const [], page: 1, limit: limit, total: 0);
    }
    final items = data['items'];
    final pagination = data['pagination'];
    final list = items is List
        ? items
              .whereType<Map<String, dynamic>>()
              .map(
                (item) => ProductModel.fromShopJson(
                  item,
                  shopId: shopId,
                  shopName: shopName,
                ),
              )
              .toList(growable: false)
        : <ProductModel>[];

    final pageNum =
        pagination is Map<String, dynamic> && pagination['page'] != null
        ? (pagination['page'] is num
              ? (pagination['page'] as num).toInt()
              : page)
        : page;
    final limitNum =
        pagination is Map<String, dynamic> && pagination['limit'] != null
        ? (pagination['limit'] is num
              ? (pagination['limit'] as num).toInt()
              : limit)
        : limit;
    final total =
        pagination is Map<String, dynamic> && pagination['total'] != null
        ? (pagination['total'] is num
              ? (pagination['total'] as num).toInt()
              : 0)
        : list.length;

    return PaginatedResult(
      items: list,
      page: pageNum,
      limit: limitNum,
      total: total,
    );
  }

  Future<List<ShopCategoryModel>> getShopProductCategories(
    String shopId, {
    bool grouped = false,
    String? categoryId,
  }) async {
    final data = await _getSuccessData(
      ApiEndpoints.shopProductCategories(shopId),
      queryParameters: {
        if (grouped) 'grouped': true,
        if (categoryId != null && categoryId.isNotEmpty) 'categoryId': categoryId,
      },
    );
    final items = (data is List)
        ? data
        : (data is Map<String, dynamic> ? data['items'] : null);
    if (items is! List) return [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(ShopCategoryModel.fromJson)
        .toList(growable: false);
  }

  Future<List<StoreReviewModel>> getShopReviews(String shopId) async {
    final data = await _getSuccessData(ApiEndpoints.shopReviews(shopId));
    final items = (data is List)
        ? data
        : (data is Map<String, dynamic> ? data['items'] : null);
    if (items is! List) return [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(StoreReviewModel.fromJson)
        .toList(growable: false);
  }

  Future<void> submitShopReview({
    required String shopId,
    required int rating,
    required String comment,
  }) async {
    await _postExpectSuccess(
      ApiEndpoints.shopReviews(shopId),
      body: {'rating': rating, 'comment': comment},
    );
  }

  Future<List<OrderModel>> getOrders({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    final data = await _getSuccessData(
      ApiEndpoints.orders,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(OrderModel.fromJson)
          .toList(growable: false);
    }
    if (data is Map<String, dynamic> && data['items'] is List) {
      return (data['items'] as List)
          .whereType<Map<String, dynamic>>()
          .map(OrderModel.fromJson)
          .toList(growable: false);
    }
    return [];
  }

  Future<void> createOrder({
    required String shopId,
    required List<Map<String, dynamic>> items,
    required List<double> deliveryCoordinates,
    String? deliveryAddress,
    String? notes,
  }) async {
    if (deliveryCoordinates.length < 2) {
      throw const ApiException('يرجى تحديد موقع التوصيل');
    }

    final mergedNotes = _mergeOrderNotes(deliveryAddress, notes);
    await _postExpectSuccess(
      ApiEndpoints.orders,
      body: {
        'shopId': shopId,
        'items': items,
        'deliveryLocation': {
          'type': 'Point',
          'coordinates': deliveryCoordinates,
        },
        if (mergedNotes != null && mergedNotes.isNotEmpty) 'notes': mergedNotes,
      },
    );
  }

  Future<String?> createOrderFromCart({
    required List<Map<String, dynamic>> shopPortions,
    required List<double> deliveryCoordinates,
    String? deliveryAddress,
    String? notes,
  }) async {
    if (deliveryCoordinates.length < 2) {
      throw const ApiException('يرجى تحديد موقع التوصيل');
    }

    final mergedNotes = _mergeOrderNotes(deliveryAddress, notes);
    final data = await _postSuccessData(
      ApiEndpoints.orders,
      body: {
        'shopPortions': shopPortions,
        'deliveryLocation': {
          'type': 'Point',
          'coordinates': deliveryCoordinates,
        },
        if (mergedNotes != null && mergedNotes.isNotEmpty) 'notes': mergedNotes,
      },
    );
    if (data is Map<String, dynamic>) {
      return data['_id']?.toString() ?? data['id']?.toString();
    }
    return null;
  }

  static String? _mergeOrderNotes(String? deliveryAddress, String? notes) {
    final parts = <String>[
      if (deliveryAddress != null && deliveryAddress.trim().isNotEmpty)
        deliveryAddress.trim(),
      if (notes != null && notes.trim().isNotEmpty) notes.trim(),
    ];
    if (parts.isEmpty) return null;
    return parts.join('\n');
  }

  Future<OrderDetailModel> getOrderById(String orderId) async {
    final data = await _getSuccessData(ApiEndpoints.order(orderId));
    if (data is! Map<String, dynamic>) {
      throw const ApiException('رد تفاصيل الطلب غير صالح');
    }
    var model = OrderDetailModel.fromApi(data);
    if (model.canRateDriver && !model.hasDriverReview) {
      final review = await _tryGetDriverReview(orderId);
      if (review != null) {
        model = model.copyWithDriverReview(review);
      }
    }
    return model;
  }

  Future<DriverReviewModel?> _tryGetDriverReview(String orderId) async {
    try {
      final data = await _getSuccessData(ApiEndpoints.orderDriverReview(orderId));
      if (data is Map && data.isNotEmpty) {
        final review = DriverReviewModel.fromJson(
          Map<String, dynamic>.from(data),
        );
        if (review.rating > 0) return review;
      }
    } catch (_) {}
    return null;
  }

  Future<DriverReviewModel> submitDriverReview({
    required String orderId,
    required int rating,
    String comment = '',
  }) async {
    final data = await _postSuccessData(
      ApiEndpoints.orderDriverReview(orderId),
      body: {
        'rating': rating,
        'comment': comment,
      },
    );
    if (data is! Map<String, dynamic>) {
      throw const ApiException('رد تقييم السائق غير صالح');
    }
    return DriverReviewModel.fromJson(data);
  }

  PaginatedResult<ProductModel> _parseProductsPaginatedData(
    dynamic data, {
    required int page,
    required int limit,
  }) {
    if (data is! Map<String, dynamic>) {
      return PaginatedResult(items: const [], page: 1, limit: limit, total: 0);
    }
    final items = data['items'];
    final pagination = data['pagination'];
    final list = items is List
        ? items
              .whereType<Map<String, dynamic>>()
              .map(ProductModel.fromJson)
              .toList(growable: false)
        : <ProductModel>[];

    final pageNum =
        pagination is Map<String, dynamic> && pagination['page'] != null
        ? (pagination['page'] is num
              ? (pagination['page'] as num).toInt()
              : page)
        : page;
    final limitNum =
        pagination is Map<String, dynamic> && pagination['limit'] != null
        ? (pagination['limit'] is num
              ? (pagination['limit'] as num).toInt()
              : limit)
        : limit;
    final total =
        pagination is Map<String, dynamic> && pagination['total'] != null
        ? (pagination['total'] is num
              ? (pagination['total'] as num).toInt()
              : 0)
        : list.length;

    return PaginatedResult(
      items: list,
      page: pageNum,
      limit: limitNum,
      total: total,
    );
  }

  Future<dynamic> _getSuccessData(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _sendSuccessData(
      () => _dio.get<dynamic>(path, queryParameters: queryParameters),
    );
  }

  Future<dynamic> _postSuccessData(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParameters,
  }) {
    return _sendSuccessData(
      () => _dio.post<dynamic>(
        path,
        data: body,
        queryParameters: queryParameters,
      ),
    );
  }

  Future<dynamic> _patchSuccessData(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParameters,
  }) {
    return _sendSuccessData(
      () => _dio.patch<dynamic>(
        path,
        data: body,
        queryParameters: queryParameters,
      ),
    );
  }

  Future<void> _postExpectSuccess(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        path,
        data: body,
        queryParameters: queryParameters,
      );
      _extractSuccessData(response);
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  Future<dynamic> _sendSuccessData(
    Future<Response<dynamic>> Function() send,
  ) async {
    try {
      final response = await send();
      return _extractSuccessData(response);
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  dynamic _extractSuccessData(Response<dynamic> response) {
    final body = response.data;
    if (body is! Map<String, dynamic>) {
      throw const ApiException('رد غير صالح من الخادم');
    }

    if (body['success'] != true) {
      final errorBody = body['error'];
      if (errorBody is Map<String, dynamic>) {
        final message = errorBody['message']?.toString() ?? 'حدث خطأ غير متوقع';
        final code = errorBody['code']?.toString();
        throw ApiException(
          message,
          code: code,
          statusCode: response.statusCode,
        );
      }
      throw const ApiException('حدث خطأ غير متوقع');
    }
    return body['data'];
  }

  ApiException _mapDioError(DioException error) {
    final statusCode = error.response?.statusCode;
    final body = error.response?.data;

    if (body is Map<String, dynamic>) {
      final errorBody = body['error'];
      if (body['success'] == false && errorBody is Map<String, dynamic>) {
        final message = errorBody['message']?.toString() ?? 'حدث خطأ غير متوقع';
        return ApiException(
          message,
          code: errorBody['code']?.toString(),
          statusCode: statusCode,
        );
      }
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException('انتهت مهلة الاتصال بالخادم');
      case DioExceptionType.connectionError:
        return const ApiException('تعذر الاتصال بالخادم');
      default:
        return ApiException(
          error.message ?? 'حدث خطأ غير متوقع',
          statusCode: statusCode,
        );
    }
  }
}
