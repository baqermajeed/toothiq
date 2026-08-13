import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../core/constants/brand_preset_icons.dart';
import '../../core/constants/category_preset_icons.dart';

import '../../model/auth_session_model.dart';
import '../../model/partner_order.dart';
import '../../model/shop_brand.dart';
import '../../model/shop_category.dart';
import '../../model/shop_product.dart';
import '../../model/shop_profile.dart';
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

  Dio get dio => _dio;

  // ─── Auth ────────────────────────────────────────────────────────────────

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

  Future<void> logout() => _postExpectSuccess(ApiEndpoints.logout);

  Future<UserModel> getMe() async {
    final data = await _getSuccessData(ApiEndpoints.currentUser);
    if (data is! Map<String, dynamic>) {
      throw const ApiException('رد بيانات المستخدم غير صالح');
    }
    return UserModel.fromJson(data);
  }

  // ─── Shops ───────────────────────────────────────────────────────────────

  Future<ShopProfile> getShop(String shopId) async {
    final data = await _getSuccessData(ApiEndpoints.shop(shopId));
    if (data is! Map<String, dynamic>) {
      throw const ApiException('رد بيانات المتجر غير صالح');
    }
    return ShopProfile.fromApi(data);
  }

  Future<ShopProfile> updateShop({
    required String shopId,
    required String name,
    required String description,
    required String address,
    required String phonePrimary,
    String? phoneSecondary,
    String? logoPath,
  }) async {
    final hasLocalLogo =
        logoPath != null && logoPath.isNotEmpty && File(logoPath).existsSync();

    if (hasLocalLogo) {
      final formData = FormData.fromMap({
        'name': name.trim(),
        'description': description.trim(),
        'phone': phonePrimary.trim(),
        if (phoneSecondary?.trim().isNotEmpty == true)
          'phone2': phoneSecondary!.trim(),
        'location': {'address': address.trim()},
        'logo': await MultipartFile.fromFile(logoPath),
      });
      final data = await _patchMultipart(ApiEndpoints.shop(shopId), formData);
      if (data is! Map<String, dynamic>) {
        throw const ApiException('رد تحديث المتجر غير صالح');
      }
      return ShopProfile.fromApi(data);
    }

    final data = await _patchSuccessData(
      ApiEndpoints.shop(shopId),
      body: {
        'name': name.trim(),
        'description': description.trim(),
        'phone': phonePrimary.trim(),
        if (phoneSecondary?.trim().isNotEmpty == true)
          'phone2': phoneSecondary!.trim(),
        'location': {'address': address.trim()},
      },
    );
    if (data is! Map<String, dynamic>) {
      throw const ApiException('رد تحديث المتجر غير صالح');
    }
    return ShopProfile.fromApi(data);
  }

  Future<String?> resolveShopIdForUser(UserModel user) async {
    if (user.shopId != null && user.shopId!.isNotEmpty) return user.shopId;

    final data = await _getSuccessData(
      ApiEndpoints.shops,
      queryParameters: {'page': 1, 'limit': 1},
    );
    if (data is Map<String, dynamic>) {
      final items = data['items'];
      if (items is List && items.isNotEmpty) {
        final first = items.first;
        if (first is Map<String, dynamic>) {
          return first['_id']?.toString() ?? first['id']?.toString();
        }
      }
    }
    return null;
  }

  // ─── Products ────────────────────────────────────────────────────────────

  Future<List<ShopProduct>> getShopProducts(String shopId) async {
    final data = await _getSuccessData(ApiEndpoints.shopProducts(shopId));
    final items = data is List
        ? data
        : (data is Map<String, dynamic> ? data['items'] : null);
    if (items is! List) return [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(ShopProduct.fromApi)
        .toList(growable: false);
  }

  Future<ShopProduct> createShopProduct({
    required String shopId,
    required ShopProduct product,
    String? imagePath,
    List<String> galleryPaths = const [],
  }) async {
    final formData = await _productFormData(
      product: product,
      imagePath: imagePath,
      galleryPaths: galleryPaths,
    );
    final data = await _postMultipart(
      ApiEndpoints.shopProducts(shopId),
      formData,
    );
    if (data is! Map<String, dynamic>) {
      throw const ApiException('رد إضافة المنتج غير صالح');
    }
    return ShopProduct.fromApi(data);
  }

  Future<ShopProduct> updateShopProduct({
    required String shopId,
    required ShopProduct product,
    String? imagePath,
    List<String> galleryPaths = const [],
  }) async {
    final formData = await _productFormData(
      product: product,
      imagePath: imagePath,
      galleryPaths: galleryPaths,
    );
    final data = await _patchMultipart(
      ApiEndpoints.shopProduct(shopId, product.id),
      formData,
    );
    if (data is! Map<String, dynamic>) {
      throw const ApiException('رد تحديث المنتج غير صالح');
    }
    return ShopProduct.fromApi(data);
  }

  Future<void> deleteShopProduct({
    required String shopId,
    required String productId,
  }) async {
    await _deleteExpectSuccess(ApiEndpoints.shopProduct(shopId, productId));
  }

  Future<ShopProduct> setProductAvailability({
    required String shopId,
    required String productId,
    required bool isAvailable,
  }) async {
    final data = await _patchSuccessData(
      ApiEndpoints.shopProduct(shopId, productId),
      body: {'isAvailable': isAvailable},
    );
    if (data is! Map<String, dynamic>) {
      throw const ApiException('رد تحديث المنتج غير صالح');
    }
    return ShopProduct.fromApi(data);
  }

  // ─── Catalog ─────────────────────────────────────────────────────────────

  Future<({List<ShopCategory> categories, List<ShopBrand> brands})>
  getCatalogTree() async {
    final data = await _getSuccessData(
      ApiEndpoints.catalogCategories,
      queryParameters: {'tree': true},
    );
    if (data is! List) {
      return (categories: <ShopCategory>[], brands: <ShopBrand>[]);
    }
    return _parseCatalogTree(data);
  }

  Future<List<ShopCategory>> getShopCategories(String shopId) async {
    try {
      final data = await _getSuccessData(
        ApiEndpoints.shopProductCategories(shopId),
      );
      final items = data is List
          ? data
          : (data is Map<String, dynamic> ? data['items'] : null);
      if (items is! List) return [];
      return _parseCategoryList(items);
    } on ApiException catch (error) {
      if (error.statusCode == 404) return [];
      rethrow;
    }
  }

  Future<void> removeShopCategory({
    required String shopId,
    required String categoryId,
  }) async {
    await _deleteExpectSuccess(
      ApiEndpoints.shopProductCategory(shopId, categoryId),
    );
  }

  Future<ShopCategory> createShopCategory({
    required String shopId,
    required String nameAr,
    String? parentCategoryId,
    String? imagePath,
  }) async {
    final imagePart = await _multipartImageFromPath(imagePath);
    if (imagePart != null) {
      final formData = FormData.fromMap({
        'nameAr': nameAr.trim(),
        if (parentCategoryId != null && parentCategoryId.isNotEmpty)
          'parentCategoryId': parentCategoryId,
        'image': imagePart,
      });
      final data = await _postMultipart(
        ApiEndpoints.shopProductCategories(shopId),
        formData,
      );
      if (data is! Map<String, dynamic>) {
        throw const ApiException('رد إنشاء القسم غير صالح');
      }
      return ShopCategory.fromApi(data);
    }

    if (parentCategoryId == null || parentCategoryId.isEmpty) {
      throw const ApiException('أيقونة القسم مطلوبة');
    }

    final data = await _postSuccessData(
      ApiEndpoints.shopProductCategories(shopId),
      body: {'parentCategoryId': parentCategoryId},
    );
    if (data is! Map<String, dynamic>) {
      throw const ApiException('رد إنشاء القسم غير صالح');
    }
    return ShopCategory.fromApi(data);
  }

  Future<ShopCategory> addAdminCategoryToShop({
    required String shopId,
    required String parentCategoryId,
  }) async {
    final data = await _postSuccessData(
      ApiEndpoints.shopProductCategories(shopId),
      body: {'parentCategoryId': parentCategoryId},
    );
    if (data is! Map<String, dynamic>) {
      throw const ApiException('رد إضافة القسم غير صالح');
    }
    return ShopCategory.fromApi(data);
  }

  Future<ShopCategory> updateShopCategory({
    required String shopId,
    required String categoryId,
    String? nameAr,
    String? imagePath,
  }) async {
    final imagePart = await _multipartImageFromPath(imagePath);
    if (imagePart != null) {
      final formData = FormData.fromMap({
        if (nameAr != null) 'nameAr': nameAr.trim(),
        'image': imagePart,
      });
      final data = await _patchMultipart(
        ApiEndpoints.shopProductCategory(shopId, categoryId),
        formData,
      );
      if (data is! Map<String, dynamic>) {
        throw const ApiException('رد تحديث القسم غير صالح');
      }
      return ShopCategory.fromApi(data);
    }

    final data = await _patchSuccessData(
      ApiEndpoints.shopProductCategory(shopId, categoryId),
      body: {
        if (nameAr != null) 'nameAr': nameAr.trim(),
      },
    );
    if (data is! Map<String, dynamic>) {
      throw const ApiException('رد تحديث القسم غير صالح');
    }
    return ShopCategory.fromApi(data);
  }

  Future<List<ShopCategory>> getCatalogCategories() async {
    final data = await _getSuccessData(ApiEndpoints.catalogCategories);
    if (data is! List) return [];
    return _parseCategoryList(data);
  }

  static ({List<ShopCategory> categories, List<ShopBrand> brands})
  _parseCatalogTree(List<dynamic> items) {
    final categories = <ShopCategory>[];
    final brands = <ShopBrand>[];
    final seenCategories = <String>{};
    final seenBrands = <String>{};

    void addCategory(Map<String, dynamic> json) {
      final category = ShopCategory.fromApi(json);
      if (category.id.isEmpty || category.nameAr.isEmpty) return;
      if (seenCategories.add(category.id)) categories.add(category);
    }

    void addBrand(Map<String, dynamic> json) {
      final brand = ShopBrand.fromApi(json);
      if (brand.id.isEmpty || brand.nameAr.isEmpty) return;
      if (seenBrands.add(brand.id)) brands.add(brand);
    }

    for (final item in items.whereType<Map<String, dynamic>>()) {
      final parentName = item['nameAr']?.toString().trim() ?? '';
      addCategory(item);

      final subs = item['subcategories'] ?? item['sections'];
      if (subs is List) {
        for (final sub in subs.whereType<Map<String, dynamic>>()) {
          final subName = sub['nameAr']?.toString().trim() ?? '';
          if (subName.isEmpty) continue;
          final displayName = parentName.isNotEmpty
              ? '$parentName · $subName'
              : subName;
          addCategory({...sub, 'nameAr': displayName});
        }
      }

      final brandList = item['brands'];
      if (brandList is List) {
        for (final brand in brandList.whereType<Map<String, dynamic>>()) {
          addBrand(brand);
        }
      }
    }

    return (categories: categories, brands: brands);
  }

  static List<ShopCategory> _parseCategoryList(List<dynamic> items) {
    final result = <ShopCategory>[];
    final seen = <String>{};

    void addCategory(Map<String, dynamic> json) {
      final category = ShopCategory.fromApi(json);
      if (category.id.isEmpty || category.nameAr.isEmpty) return;
      if (seen.add(category.id)) result.add(category);
    }

    for (final item in items.whereType<Map<String, dynamic>>()) {
      addCategory(item);
      for (final key in ['sections', 'subcategories']) {
        final nested = item[key];
        if (nested is List) {
          for (final sub in nested.whereType<Map<String, dynamic>>()) {
            addCategory(sub);
          }
        }
      }
    }

    return result;
  }

  Future<List<ShopBrand>> getBrands({String? shopId}) async {
    final tree = await getCatalogTree();
    return tree.brands;
  }

  // ─── Orders ──────────────────────────────────────────────────────────────

  Future<List<PartnerOrder>> getOrders({
    String? status,
    int page = 1,
    int limit = 50,
  }) async {
    final data = await _getSuccessData(
      ApiEndpoints.orders,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );

    List<dynamic> rawItems;
    if (data is List) {
      rawItems = data;
    } else if (data is Map<String, dynamic> && data['items'] is List) {
      rawItems = data['items'] as List;
    } else {
      return [];
    }

    return rawItems
        .whereType<Map<String, dynamic>>()
        .map(PartnerOrder.fromApi)
        .toList(growable: false);
  }

  Future<PartnerOrder> getOrderById(String orderId) async {
    final data = await _getSuccessData(ApiEndpoints.order(orderId));
    if (data is! Map<String, dynamic>) {
      throw const ApiException('رد تفاصيل الطلب غير صالح');
    }
    return PartnerOrder.fromApi(data);
  }

  Future<PartnerOrder> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    final data = await _patchSuccessData(
      ApiEndpoints.orderStatus(orderId),
      body: {'status': status},
    );
    if (data is Map<String, dynamic>) {
      return PartnerOrder.fromApi(data);
    }
    return getOrderById(orderId);
  }

  Future<List<PartnerOrder>> getDriverOrders({
    required String tab,
    int page = 1,
    int limit = 50,
  }) async {
    final data = await _getSuccessData(
      ApiEndpoints.driverOrders,
      queryParameters: {
        'tab': tab,
        'page': page,
        'limit': limit,
      },
    );

    List<dynamic> rawItems;
    if (data is List) {
      rawItems = data;
    } else if (data is Map<String, dynamic> && data['items'] is List) {
      rawItems = data['items'] as List;
    } else {
      return [];
    }

    return rawItems
        .whereType<Map<String, dynamic>>()
        .map(PartnerOrder.fromApi)
        .toList(growable: false);
  }

  Future<PartnerOrder> acceptDriverOrder(String orderId) async {
    final data = await _postSuccessData(ApiEndpoints.driverAcceptOrder(orderId));
    if (data is! Map<String, dynamic>) {
      throw const ApiException('رد قبول الطلب غير صالح');
    }
    return PartnerOrder.fromApi(data);
  }

  Future<PartnerOrder> updateDriverOrderStatus({
    required String orderId,
    required String status,
  }) async {
    final data = await _patchSuccessData(
      ApiEndpoints.driverOrderStatus(orderId),
      body: {'status': status},
    );
    if (data is Map<String, dynamic>) {
      return PartnerOrder.fromApi(data);
    }
    throw const ApiException('رد تحديث حالة الطلب غير صالح');
  }

  // ─── HTTP helpers ────────────────────────────────────────────────────────

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final path = options.path;
    final isAuthPublic = path.contains('/auth/login') ||
        path.contains('/auth/refresh') ||
        path.contains('/auth/register');

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

  Future<MultipartFile?> _multipartImageFromPath(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) return null;

    if (CategoryPresetIcons.isAssetPath(imagePath) ||
        BrandPresetIcons.isAssetPath(imagePath)) {
      final data = await rootBundle.load(imagePath);
      final fileName = imagePath.split('/').last;
      return MultipartFile.fromBytes(
        data.buffer.asUint8List(),
        filename: fileName,
      );
    }

    if (File(imagePath).existsSync()) {
      return MultipartFile.fromFile(imagePath);
    }

    return null;
  }

  Future<FormData> _productFormData({
    required ShopProduct product,
    String? imagePath,
    List<String> galleryPaths = const [],
  }) async {
    final map = <String, dynamic>{};
    for (final entry in product.toApiBody().entries) {
      final value = entry.value;
      if (value == null) continue;
      map[entry.key] = value is bool ? value.toString() : value.toString();
    }

    if (imagePath != null &&
        imagePath.isNotEmpty &&
        File(imagePath).existsSync()) {
      map['image'] = await MultipartFile.fromFile(imagePath);
    }

    final galleryFiles = <MultipartFile>[];
    for (final path in galleryPaths) {
      if (path.isNotEmpty && File(path).existsSync()) {
        galleryFiles.add(await MultipartFile.fromFile(path));
      }
    }
    if (galleryFiles.isNotEmpty) {
      map['images'] = galleryFiles;
    }

    return FormData.fromMap(map);
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

  Future<dynamic> _postMultipart(String path, FormData formData) {
    return _sendSuccessData(
      () => _dio.post<dynamic>(
        path,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      ),
    );
  }

  Future<dynamic> _patchMultipart(String path, FormData formData) {
    return _sendSuccessData(
      () => _dio.patch<dynamic>(
        path,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
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

  Future<void> _deleteExpectSuccess(String path) async {
    try {
      final response = await _dio.delete<dynamic>(path);
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
        throw ApiException(
          errorBody['message']?.toString() ?? 'حدث خطأ غير متوقع',
          code: errorBody['code']?.toString(),
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
        return ApiException(
          errorBody['message']?.toString() ?? 'حدث خطأ غير متوقع',
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
