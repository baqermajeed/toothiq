import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/config/api_config.dart';
import '../core/errors/api_exception.dart';
import '../models/auth_result.dart';
import '../models/order.dart';
import '../models/paginated_result.dart';
import '../models/product.dart';
import '../models/shop.dart';
import '../models/user.dart';
import '../models/voice_order_zone_check_result.dart';
import '../models/contact_info.dart';
import '../models/app_version_check_result.dart';
import 'token_storage.dart';

/// عميل HTTP للمصادقة؛ عند 401 يُمسَح التوكن ويُستدعى onSessionExpired (بدون refresh).
class ApiClient {
  ApiClient({
    required TokenStorage tokenStorage,
    VoidCallback? onSessionExpired,
  })  : _tokenStorage = tokenStorage,
        _onSessionExpired = onSessionExpired {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: _onRequest,
      onError: _onError,
    ));
  }

  final TokenStorage _tokenStorage;
  final VoidCallback? _onSessionExpired;
  late final Dio _dio;

  static const _authRefreshPath = '${ApiConfig.authPrefix}/refresh';

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final path = options.path;
    final isAuthPublic = path.contains('/auth/register') ||
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
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }
    await _tokenStorage.clearTokens();
    _onSessionExpired?.call();
    return handler.next(err);
  }

  Future<AuthResult> register(Map<String, dynamic> body) async {
    final response = await _dio.post(
      '${ApiConfig.authPrefix}/register',
      data: body,
    );
    return _parseAuthResponse(response);
  }

  Future<AuthResult> login(
    String phone,
    String password, {
    List<double>? location,
  }) async {
    final data = <String, dynamic>{'phone': phone, 'password': password};
    if (location != null && location.length >= 2) {
      data['location'] = {
        'type': 'Point',
        'coordinates': [location[0], location[1]],
      };
    }
    try {
      final response = await _dio.post(
        '${ApiConfig.authPrefix}/login',
        data: data,
      );
      debugPrint('[Login API] رد السيرفر (نجاح): ${response.data}');
      return _parseAuthResponse(response);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode ?? 0;
      final body = e.response?.data;
      debugPrint('[Login API] رد السيرفر (فشل): statusCode=$statusCode, data=$body');
      final bodyMap = body is Map<String, dynamic> ? body : <String, dynamic>{};
      throw ApiException.fromResponse(bodyMap, statusCode);
    }
  }

  Future<AuthResult> guestRegister(Map<String, dynamic> body) async {
    final response = await _dio.post(
      '${ApiConfig.authPrefix}/guest-register',
      data: body,
    );
    return _parseAuthResponse(response);
  }

  Future<AuthResult> refresh(String refreshToken) async {
    final response = await _dio.post(
      _authRefreshPath,
      data: {'refreshToken': refreshToken},
    );
    return _parseAuthResponse(response);
  }

  AuthResult _parseAuthResponse(Response<dynamic> response) {
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const ApiException(message: 'Invalid response');
    }
    if (data['success'] != true) {
      throw ApiException.fromResponse(data, response.statusCode ?? 0);
    }
    return AuthResult.fromJson(data);
  }

  /// التحقق من كون النقطة [lng, lat] داخل منطقة طلب صوتي فقط.
  /// يستدعى GET /api/zones/voice-order/check
  Future<VoiceOrderZoneCheckResult> checkVoiceOrderZone(double lng, double lat) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.zonesPrefix}/voice-order/check',
        queryParameters: {'lng': lng, 'lat': lat},
      );
      final data = response.data;
      if (data is! Map<String, dynamic> || data['success'] != true) {
        return const VoiceOrderZoneCheckResult(inside: false);
      }
      final rawData = data['data'];
      if (rawData is! Map<String, dynamic>) {
        return const VoiceOrderZoneCheckResult(inside: false);
      }
      return VoiceOrderZoneCheckResult.fromJson(rawData);
    } on DioException catch (_) {
      return const VoiceOrderZoneCheckResult(inside: false);
    }
  }

  /// التحقق من إصدار التطبيق — يُرجع إن كان التحديث مطلوباً وربطه المتجر.
  /// عام، لا يحتاج مصادقة.
  Future<AppVersionCheckResult?> getAppVersionCheck(String currentVersion) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.appVersionPrefix}/check',
        queryParameters: {'version': currentVersion},
      );
      final data = response.data;
      if (data is! Map<String, dynamic> || data['success'] != true) {
        return null;
      }
      final rawData = data['data'];
      if (rawData is! Map<String, dynamic>) return null;
      return AppVersionCheckResult.fromJson(rawData);
    } on DioException catch (_) {
      return null;
    }
  }

  /// جلب معلومات التواصل (فيسبوك، انستغرام، رقم الدعم) — عام، لا يحتاج مصادقة.
  Future<ContactInfo> getContactInfo() async {
    try {
      final response = await _dio.get(ApiConfig.appContactPrefix);
      final data = response.data;
      if (data is! Map<String, dynamic> || data['success'] != true) {
        return ContactInfo.empty;
      }
      final rawData = data['data'];
      if (rawData is! Map<String, dynamic>) return ContactInfo.empty;
      return ContactInfo.fromJson(rawData);
    } on DioException catch (_) {
      return ContactInfo.empty;
    }
  }

  /// جلب قائمة التصنيفات من الـ API (عام، لا يحتاج مصادقة).
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await _dio.get(ApiConfig.categoriesPrefix);
      final data = response.data;
      if (data is! Map<String, dynamic> || data['success'] != true) {
        return [];
      }
      final rawData = data['data'];
      if (rawData is! List) return [];
      return rawData
          .whereType<Map<String, dynamic>>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } on DioException catch (_) {
      return [];
    }
  }

  /// جلب قائمة المحلات من الـ API.
  /// [lng] و [lat] اختياريان — يُستخدمان للضيف أو عند عدم وجود موقع المستخدم.
  /// [category] اختياري — اسم التصنيف لفلترة المحلات من السيرفر.
  Future<List<Shop>> getShops({double? lng, double? lat, String? category}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (lng != null && lat != null && lng.isFinite && lat.isFinite) {
        queryParams['lng'] = lng;
        queryParams['lat'] = lat;
      }
      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }
      final response = await _dio.get(
        ApiConfig.shopsPrefix,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      final data = response.data;
      if (data is! Map<String, dynamic> || data['success'] != true) {
        throw ApiException.fromResponse(
          data is Map<String, dynamic> ? data : <String, dynamic>{},
          response.statusCode ?? 0,
        );
      }
      final rawData = data['data'];
      if (rawData is! Map<String, dynamic>) {
        return [];
      }
      final items = rawData['items'];
      if (items is! List) {
        return [];
      }
      return items
          .whereType<Map<String, dynamic>>()
          .map((e) => Shop.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromResponse(
        e.response?.data is Map<String, dynamic>
            ? e.response!.data as Map<String, dynamic>
            : <String, dynamic>{},
        e.response?.statusCode ?? 0,
      );
    }
  }

  /// جلب قائمة المحلات مع pagination (لصفحة «كل المحلات»).
  Future<PaginatedResult<Shop>> getShopsPaginated({
    int page = 1,
    int limit = 12,
    double? lng,
    double? lat,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'limit': limit};
      if (lng != null && lat != null && lng.isFinite && lat.isFinite) {
        queryParams['lng'] = lng;
        queryParams['lat'] = lat;
      }
      final response = await _dio.get(
        ApiConfig.shopsPrefix,
        queryParameters: queryParams,
      );
      final data = response.data;
      if (data is! Map<String, dynamic> || data['success'] != true) {
        throw ApiException.fromResponse(
          data is Map<String, dynamic> ? data : <String, dynamic>{},
          response.statusCode ?? 0,
        );
      }
      final rawData = data['data'];
      if (rawData is! Map<String, dynamic>) {
        return PaginatedResult(items: [], page: 1, limit: limit, total: 0);
      }
      final items = rawData['items'];
      final pagination = rawData['pagination'];
      final list = items is List
          ? items
              .whereType<Map<String, dynamic>>()
              .map((e) => Shop.fromJson(e))
              .toList()
          : <Shop>[];
      final pageNum = pagination is Map<String, dynamic> && pagination['page'] != null
          ? (pagination['page'] is num ? (pagination['page'] as num).toInt() : page)
          : page;
      final limitNum = pagination is Map<String, dynamic> && pagination['limit'] != null
          ? (pagination['limit'] is num ? (pagination['limit'] as num).toInt() : limit)
          : limit;
      final total = pagination is Map<String, dynamic> && pagination['total'] != null
          ? (pagination['total'] is num ? (pagination['total'] as num).toInt() : 0)
          : list.length;
      return PaginatedResult(items: list, page: pageNum, limit: limitNum, total: total);
    } on DioException catch (e) {
      throw ApiException.fromResponse(
        e.response?.data is Map<String, dynamic>
            ? e.response!.data as Map<String, dynamic>
            : <String, dynamic>{},
        e.response?.statusCode ?? 0,
      );
    }
  }

  /// بحث عن منتجات بالاسم عبر كل المحلات مع pagination.
  /// عند تمرير [lng] و [lat] يفلتر حسب المنطقة.
  Future<PaginatedResult<Product>> searchProducts(
    String query, {
    int page = 1,
    int limit = 12,
    double? lng,
    double? lat,
  }) async {
    try {
      final q = query.trim();
      final queryParams = <String, dynamic>{'page': page, 'limit': limit};
      if (q.isNotEmpty) queryParams['q'] = q;
      if (lng != null && lat != null && lng.isFinite && lat.isFinite) {
        queryParams['lng'] = lng;
        queryParams['lat'] = lat;
      }

      // طباعة تفاصيل الريكوست قبل الإرسال لمعرفة ما يتم إرساله للسيرفر
      print('[SearchProducts API][REQUEST] rawQuery="$query" trimmed="$q"');
      print(
        '[SearchProducts API][REQUEST] page=$page, limit=$limit, '
        'lng=$lng, lat=$lat, queryParams=$queryParams',
      );

      final response = await _dio.get(
        '${ApiConfig.productsPrefix}/search',
        queryParameters: queryParams,
      );
      // طباعة رد السيرفر عند البحث عن منتجات (لأغراض الـ debugging)
      print('[SearchProducts API] statusCode: ${response.statusCode}');
      print('[SearchProducts API] response: ${response.data}');

      final data = response.data;
      if (data is! Map<String, dynamic> || data['success'] != true) {
        throw ApiException.fromResponse(
          data is Map<String, dynamic> ? data : <String, dynamic>{},
          response.statusCode ?? 0,
        );
      }
      final rawData = data['data'];
      if (rawData is! Map<String, dynamic>) {
        return PaginatedResult(items: [], page: 1, limit: limit, total: 0);
      }
      final items = rawData['items'];
      final pagination = rawData['pagination'];
      final pageNum = pagination is Map ? (pagination['page'] as num?)?.toInt() ?? page : page;
      final limitNum = pagination is Map ? (pagination['limit'] as num?)?.toInt() ?? limit : limit;
      final total = pagination is Map ? (pagination['total'] as num?)?.toInt() ?? 0 : 0;
      final list = items is List
          ? (items)
              .whereType<Map<String, dynamic>>()
              .map((e) {
                final map = Map<String, dynamic>.from(e);
                if (!map.containsKey('emoji')) map['emoji'] = '🛒';
                return Product.fromMap(map);
              })
              .toList()
          : <Product>[];
      return PaginatedResult(items: list, page: pageNum, limit: limitNum, total: total);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode ?? 0;
      final body = e.response?.data;
      final bodyMap = body is Map<String, dynamic> ? body : <String, dynamic>{};
      // طباعة رد السيرفر في حالة الخطأ أثناء البحث عن منتجات
      print('[SearchProducts API] خطأ $statusCode: $bodyMap');
      throw ApiException.fromResponse(bodyMap, statusCode);
    }
  }

  /// جلب منتجات من كل المحلات مع pagination.
  /// عند تمرير [lng] و [lat] يفلتر الـ API حسب المنطقة — يعرض فقط منتجات محلات توصّل للمنطقة.
  /// إن كانت المنطقة غير مدعومة يُرجع قائمة فارغة.
  Future<PaginatedResult<Product>> getProducts({
    int page = 1,
    int limit = 12,
    double? lng,
    double? lat,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'limit': limit};
      if (lng != null && lat != null && lng.isFinite && lat.isFinite) {
        queryParams['lng'] = lng;
        queryParams['lat'] = lat;
      }
      final response = await _dio.get(
        ApiConfig.productsPrefix,
        queryParameters: queryParams,
      );
      final data = response.data;
      if (data is! Map<String, dynamic> || data['success'] != true) {
        throw ApiException.fromResponse(
          data is Map<String, dynamic> ? data : <String, dynamic>{},
          response.statusCode ?? 0,
        );
      }
      final rawData = data['data'];
      if (rawData is! Map<String, dynamic>) {
        return PaginatedResult(items: [], page: 1, limit: limit, total: 0);
      }
      final items = rawData['items'];
      final pagination = rawData['pagination'];
      final pageNum = pagination is Map ? (pagination['page'] as num?)?.toInt() ?? 1 : 1;
      final limitNum = pagination is Map ? (pagination['limit'] as num?)?.toInt() ?? limit : limit;
      final total = pagination is Map ? (pagination['total'] as num?)?.toInt() ?? 0 : 0;

      final list = items is List
          ? (items)
              .whereType<Map<String, dynamic>>()
              .map((e) {
                final map = Map<String, dynamic>.from(e);
                if (!map.containsKey('emoji')) map['emoji'] = '🛒';
                return Product.fromMap(map);
              })
              .toList()
          : <Product>[];

      return PaginatedResult(items: list, page: pageNum, limit: limitNum, total: total);
    } on DioException catch (e) {
      throw ApiException.fromResponse(
        e.response?.data is Map<String, dynamic>
            ? e.response!.data as Map<String, dynamic>
            : <String, dynamic>{},
        e.response?.statusCode ?? 0,
      );
    }
  }

  /// جلب منتجات محل معيّن مع pagination. يُضاف shopId و shopName إلى كل منتج.
  Future<PaginatedResult<Product>> getProductsByShop(
    String shopId, {
    String? shopName,
    int page = 1,
    int limit = 20,
    String? query,
  }) async {
    try {
      final q = query?.trim() ?? '';
      final queryParams = <String, dynamic>{'page': page, 'limit': limit};
      if (q.isNotEmpty) {
        queryParams['q'] = q;
      }
      final response = await _dio.get(
        '${ApiConfig.shopsPrefix}/$shopId/products',
        queryParameters: queryParams,
      );
      final data = response.data;
      if (data is! Map<String, dynamic> || data['success'] != true) {
        throw ApiException.fromResponse(
          data is Map<String, dynamic> ? data : <String, dynamic>{},
          response.statusCode ?? 0,
        );
      }
      final rawData = data['data'];
      if (rawData is! Map<String, dynamic>) {
        return PaginatedResult(items: [], page: 1, limit: limit, total: 0);
      }
      final items = rawData['items'];
      final pagination = rawData['pagination'];
      final pageNum = pagination is Map ? (pagination['page'] as num?)?.toInt() ?? page : page;
      final limitNum = pagination is Map ? (pagination['limit'] as num?)?.toInt() ?? limit : limit;
      final total = pagination is Map ? (pagination['total'] as num?)?.toInt() ?? 0 : 0;
      final list = items is List
          ? (items)
              .whereType<Map<String, dynamic>>()
              .map((e) {
                final map = Map<String, dynamic>.from(e);
                map['shopId'] = shopId;
                if (shopName != null) map['shopName'] = shopName;
                if (!map.containsKey('emoji')) map['emoji'] = '🛒';
                return Product.fromMap(map);
              })
              .toList()
          : <Product>[];
      return PaginatedResult(items: list, page: pageNum, limit: limitNum, total: total);
    } on DioException catch (e) {
      throw ApiException.fromResponse(
        e.response?.data is Map<String, dynamic>
            ? e.response!.data as Map<String, dynamic>
            : <String, dynamic>{},
        e.response?.statusCode ?? 0,
      );
    }
  }

  /// جلب المستخدم الحالي باستخدام التوكن المحفوظ. يُرجع null عند الفشل.
  Future<User?> getMe() async {
    try {
      final response = await _dio.get('${ApiConfig.usersPrefix}/me');
      final data = response.data;
      if (data is! Map<String, dynamic> || data['success'] != true) {
        return null;
      }
      final userData = data['data'];
      if (userData is! Map<String, dynamic>) {
        return null;
      }
      return User.fromJson(userData);
    } catch (_) {
      return null;
    }
  }

  /// تحديث توكن FCM للمستخدم الحالي.
  Future<void> updateFcmToken(String? token) async {
    try {
      await _dio.patch(
        '${ApiConfig.usersPrefix}/me',
        data: {'fcmToken': token},
      );
    } catch (_) {
      // لا نفشل التطبيق عند فشل تحديث التوكن
    }
  }

  /// تحديث بيانات المستخدم الحالي (الاسم، عنوان التوصيل).
  /// [location] إحداثيات [lng, lat] أو null للإبقاء على القيمة الحالية.
  Future<User> updateMe({
    required String name,
    List<double>? location,
  }) async {
    final response = await _dio.patch(
      '${ApiConfig.usersPrefix}/me',
      data: {
        'name': name,
        if (location != null && location.length >= 2)
          'location': {
            'type': 'Point',
            'coordinates': [location[0], location[1]],
          },
      },
    );
    final data = response.data;
    if (data is! Map<String, dynamic> || data['success'] != true) {
      throw ApiException.fromResponse(
        data is Map<String, dynamic> ? data : <String, dynamic>{},
        response.statusCode ?? 0,
      );
    }
    final userData = data['data'];
    if (userData is! Map<String, dynamic>) {
      throw const ApiException(message: 'Invalid user response');
    }
    return User.fromJson(userData);
  }

  /// رفع ملف صوتي لملاحظة الطلب. يُرجع رابط الملف لاستخدامه في [createOrder].
  Future<String> uploadOrderNoteAudio(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'audio': await MultipartFile.fromFile(filePath),
      });
      final response = await _dio.post(
        '${ApiConfig.ordersPrefix}/note-audio',
        data: formData,
      );
      final data = response.data;
      if (data is! Map<String, dynamic> || data['success'] != true) {
        throw ApiException.fromResponse(
          data is Map<String, dynamic> ? data : <String, dynamic>{},
          response.statusCode ?? 0,
        );
      }
      final result = data['data'];
      if (result is! Map<String, dynamic>) {
        throw const ApiException(message: 'Invalid upload response');
      }
      final url = result['url'] as String?;
      if (url == null || url.isEmpty) {
        throw const ApiException(message: 'No URL in upload response');
      }
      return url.startsWith('http') ? url : '${ApiConfig.baseUrl}$url';
    } on DioException catch (e) {
      debugPrint('[uploadOrderNoteAudio] DioException: ${e.type}');
      debugPrint('[uploadOrderNoteAudio] message: ${e.message}');
      debugPrint('[uploadOrderNoteAudio] response statusCode: ${e.response?.statusCode}');
      debugPrint('[uploadOrderNoteAudio] response data: ${e.response?.data}');
      debugPrint('[uploadOrderNoteAudio] error: $e');
      throw ApiException.fromResponse(
        e.response?.data is Map<String, dynamic> ? e.response!.data as Map<String, dynamic> : <String, dynamic>{},
        e.response?.statusCode ?? 0,
      );
    }
  }

  /// إنشاء طلب صوتي فقط (بدون منتجات ولا محل — لمناطق الطلب الصوتي فقط).
  Future<Order> createVoiceOrderWithoutShop({
    required List<double> deliveryCoordinates,
    required String notesAudioUrl,
  }) async {
    try {
      final response = await _dio.post(
        '${ApiConfig.ordersPrefix}/voice',
        data: {
          'deliveryLocation': {
            'type': 'Point',
            'coordinates': deliveryCoordinates,
          },
          'notesAudioUrl': notesAudioUrl,
        },
      );
      final data = response.data;
      if (data is! Map<String, dynamic> || data['success'] != true) {
        throw ApiException.fromResponse(
          data is Map<String, dynamic> ? data : <String, dynamic>{},
          response.statusCode ?? 0,
        );
      }
      final orderData = data['data'];
      if (orderData is! Map<String, dynamic>) {
        throw const ApiException(message: 'Invalid order response');
      }
      return Order.fromJson(orderData);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode ?? 0;
      final body = e.response?.data;
      final bodyMap = body is Map<String, dynamic> ? body : <String, dynamic>{};
      debugPrint('[createVoiceOrderWithoutShop] خطأ $statusCode: $bodyMap');
      throw ApiException.fromResponse(bodyMap, statusCode);
    }
  }

  /// إنشاء طلب صوتي فقط (بدون منتجات) لمحل معيّن. يُستخدم من [OrderService.createVoiceOrder].
  Future<Order> createVoiceOrder({
    required String shopId,
    required List<double> deliveryCoordinates,
    required String notesAudioUrl,
  }) async {
    try {
      final response = await _dio.post(
        '${ApiConfig.ordersPrefix}/voice',
        data: {
          'shopId': shopId,
          'deliveryLocation': {
            'type': 'Point',
            'coordinates': deliveryCoordinates,
          },
          'notesAudioUrl': notesAudioUrl,
        },
      );
      final data = response.data;
      if (data is! Map<String, dynamic> || data['success'] != true) {
        throw ApiException.fromResponse(
          data is Map<String, dynamic> ? data : <String, dynamic>{},
          response.statusCode ?? 0,
        );
      }
      final orderData = data['data'];
      if (orderData is! Map<String, dynamic>) {
        throw const ApiException(message: 'Invalid order response');
      }
      return Order.fromJson(orderData);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode ?? 0;
      final body = e.response?.data;
      final bodyMap = body is Map<String, dynamic> ? body : <String, dynamic>{};
      debugPrint('[createVoiceOrder] خطأ $statusCode: $bodyMap');
      throw ApiException.fromResponse(bodyMap, statusCode);
    }
  }

  /// إنشاء طلب واحد (قد يكون من محلات متعددة).
  /// [shopPortions] قائمة أجزاء الطلب، كل جزء: { shopId, items: [...] }
  Future<Order> createOrder({
    required List<Map<String, dynamic>> shopPortions,
    required List<double> deliveryCoordinates,
    String? notes,
    String? notesAudioUrl,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.ordersPrefix,
        data: {
          'shopPortions': shopPortions,
          'deliveryLocation': {
            'type': 'Point',
            'coordinates': deliveryCoordinates,
          },
          if (notes != null && notes.isNotEmpty) 'notes': notes,
          if (notesAudioUrl != null && notesAudioUrl.isNotEmpty) 'notesAudioUrl': notesAudioUrl,
        },
      );
      debugPrint('[Order API] statusCode: ${response.statusCode}');
      debugPrint('[Order API] response: ${response.data}');
      final data = response.data;
      if (data is! Map<String, dynamic> || data['success'] != true) {
        throw ApiException.fromResponse(
          data is Map<String, dynamic> ? data : <String, dynamic>{},
          response.statusCode ?? 0,
        );
      }
      final orderData = data['data'];
      if (orderData is! Map<String, dynamic>) {
        throw const ApiException(message: 'Invalid order response');
      }
      return Order.fromJson(orderData);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode ?? 0;
      final body = e.response?.data;
      final bodyMap = body is Map<String, dynamic> ? body : <String, dynamic>{};
      debugPrint('[Order API] خطأ $statusCode: $bodyMap');
      throw ApiException.fromResponse(bodyMap, statusCode);
    }
  }

  /// جلب طلب واحد بالمعرّف (لشاشة التفاصيل / التتبع).
  Future<Order> getOrderById(String orderId) async {
    try {
      final response = await _dio.get('${ApiConfig.ordersPrefix}/$orderId');
      final data = response.data;
      if (data is! Map<String, dynamic> || data['success'] != true) {
        throw ApiException.fromResponse(
          data is Map<String, dynamic> ? data : <String, dynamic>{},
          response.statusCode ?? 0,
        );
      }
      final orderData = data['data'];
      if (orderData is! Map<String, dynamic>) {
        throw const ApiException(message: 'Invalid order response');
      }
      return Order.fromJson(orderData);
    } on DioException catch (e) {
      throw ApiException.fromResponse(
        e.response?.data is Map<String, dynamic>
            ? e.response!.data as Map<String, dynamic>
            : <String, dynamic>{},
        e.response?.statusCode ?? 0,
      );
    }
  }

  /// جلب قائمة الطلبات للمستخدم الحالي مع pagination.
  Future<PaginatedResult<Order>> getOrders({int page = 1, int limit = 20, String? status}) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'limit': limit};
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      final response = await _dio.get(
        ApiConfig.ordersPrefix,
        queryParameters: queryParams,
      );
      final data = response.data;
      if (data is! Map<String, dynamic> || data['success'] != true) {
        throw ApiException.fromResponse(
          data is Map<String, dynamic> ? data : <String, dynamic>{},
          response.statusCode ?? 0,
        );
      }
      final rawData = data['data'];
      if (rawData is! Map<String, dynamic>) {
        return PaginatedResult(items: [], page: 1, limit: limit, total: 0);
      }
      final itemsRaw = rawData['items'];
      final pagination = rawData['pagination'];
      final pageNum = pagination is Map ? (pagination['page'] as num?)?.toInt() ?? page : page;
      final limitNum = pagination is Map ? (pagination['limit'] as num?)?.toInt() ?? limit : limit;
      final total = pagination is Map ? (pagination['total'] as num?)?.toInt() ?? 0 : 0;
      final list = itemsRaw is List
          ? itemsRaw
              .whereType<Map<String, dynamic>>()
              .map((e) => Order.fromJson(e))
              .toList()
          : <Order>[];
      return PaginatedResult(items: list, page: pageNum, limit: limitNum, total: total);
    } on DioException catch (e) {
      throw ApiException.fromResponse(
        e.response?.data is Map<String, dynamic>
            ? e.response!.data as Map<String, dynamic>
            : <String, dynamic>{},
        e.response?.statusCode ?? 0,
      );
    }
  }

  /// لاستخدامه من خارج المصادقة (طلبات محمية) — نفس الـ Dio مع الاعتراضات.
  Dio get dio => _dio;
}
