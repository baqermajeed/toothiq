/// حالات الطلب وفق الباكند (ORDER_STATUS).
enum OrderStatus {
  pending('pending', 'قيد الانتظار'),
  accepted('accepted', 'مقبول'),
  preparing('preparing', 'قيد التحضير'),
  onTheWay('on_the_way', 'في الطريق'),
  delivered('delivered', 'تم التوصيل'),
  canceled('canceled', 'ملغي');

  const OrderStatus(this.value, this.labelAr);
  final String value;
  final String labelAr;

  static OrderStatus? fromValue(String? v) {
    if (v == null) return null;
    for (final e in OrderStatus.values) {
      if (e.value == v) return e;
    }
    return null;
  }
}

/// عنصر طلب (منتج داخل الطلب).
class OrderItem {
  const OrderItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
  });

  final String productId;
  final String name;
  final double price;
  final int quantity;

  double get lineTotal => price * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: (json['productId'] ?? json['product_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      price: (json['price'] is num) ? (json['price'] as num).toDouble() : 0,
      quantity: (json['quantity'] is int) ? json['quantity'] as int : (json['quantity'] is num) ? (json['quantity'] as num).toInt() : 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'name': name,
        'price': price,
        'quantity': quantity,
      };
}

/// جزء الطلب من محل واحد (للطلبات متعددة المحلات).
class ShopPortion {
  const ShopPortion({
    required this.shopId,
    this.shopName,
    this.shopLat,
    this.shopLng,
    required this.items,
    required this.subtotal,
  });

  final String shopId;
  final String? shopName;
  /// إحداثيات موقع المحل (من shopId.location عند populate). null إن لم يُرجَع.
  final double? shopLat;
  final double? shopLng;
  final List<OrderItem> items;
  final double subtotal;

  factory ShopPortion.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final itemsList = rawItems is List
        ? (rawItems)
            .whereType<Map<String, dynamic>>()
            .map((e) => OrderItem.fromJson(e))
            .toList()
        : <OrderItem>[];
    final shop = json['shopId'];
    String? shopName;
    double? shopLat;
    double? shopLng;
    if (shop is Map<String, dynamic>) {
      shopName = shop['name'] as String?;
      final loc = shop['location'];
      if (loc is Map<String, dynamic> && loc['coordinates'] is List) {
        final coords = loc['coordinates'] as List;
        if (coords.length >= 2) {
          final lng = (coords[0] is num) ? (coords[0] as num).toDouble() : null;
          final lat = (coords[1] is num) ? (coords[1] as num).toDouble() : null;
          if (lng != null && lat != null) {
            shopLng = lng;
            shopLat = lat;
          }
        }
      }
    }
    return ShopPortion(
      shopId: (shop is Map ? shop['_id'] : shop)?.toString() ?? '',
      shopName: shopName,
      shopLat: shopLat,
      shopLng: shopLng,
      items: itemsList,
      subtotal: (json['subtotal'] is num) ? (json['subtotal'] as num).toDouble() : 0,
    );
  }
}

/// نموذج الطلب — يطابق استجابة الباكند (Order + populate shopId, shopPortions, driverId).
class Order {
  const Order({
    required this.id,
    this.shopId = '',
    this.shopName,
    this.shopLat,
    this.shopLng,
    this.items = const [],
    this.shopPortions,
    required this.totalPrice,
    required this.deliveryFee,
    required this.status,
    this.notes,
    this.notesAudioUrl,
    this.createdAt,
    this.updatedAt,
    this.deliveryLat,
    this.deliveryLng,
    this.driverId,
    this.driverName,
    this.driverPhone,
    this.driverPhoto,
    this.driverLat,
    this.driverLng,
    this.customerName,
    this.customerPhone,
  });

  final String id;
  final String shopId;
  final String? shopName;
  /// إحداثيات موقع المحل (للطلب من محل واحد، من shopId.location عند populate). null إن لم يُرجَع.
  final double? shopLat;
  final double? shopLng;
  final List<OrderItem> items;
  /// أجزاء الطلب من كل محل (للطلبات متعددة المحلات). إن وُجد تُستخدم للعرض بدل items.
  final List<ShopPortion>? shopPortions;
  final double totalPrice;
  final double deliveryFee;
  final OrderStatus status;
  final String? notes;
  final String? notesAudioUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  /// إحداثيات عنوان التوصيل (GeoJSON: [lng, lat]). null إن لم يُرجَع من الـ API.
  final double? deliveryLat;
  final double? deliveryLng;
  /// معرّف السائق (إن وُجد). null إن لم يُرجَع من الـ API.
  final String? driverId;
  /// اسم السائق
  final String? driverName;
  /// رقم هاتف السائق
  final String? driverPhone;
  /// صورة السائق (من driverId.avatar). null إن لم يُرجَع.
  final String? driverPhoto;
  /// إحداثيات موقع السائق (من driverId.location). null إن لم يُرجَع.
  final double? driverLat;
  final double? driverLng;
  /// اسم العميل (من customerId). null إن لم يُرجَع من الـ API.
  final String? customerName;
  /// رقم هاتف العميل. null إن لم يُرجَع من الـ API.
  final String? customerPhone;

  double get grandTotal => totalPrice + deliveryFee;

  /// جميع المنتجات (من shopPortions إن وُجدت، وإلا من items).
  List<OrderItem> get allItems {
    if (shopPortions != null && shopPortions!.isNotEmpty) {
      return shopPortions!.expand((p) => p.items).toList();
    }
    return items;
  }

  /// هل الطلب من عدة محلات؟
  bool get isMultiShop => shopPortions != null && shopPortions!.length > 1;

  /// قائمة مواقع المحلات التي طلب منها (للعرض على الخريطة). كل عنصر: {lat, lng, name?}.
  List<Map<String, dynamic>> get shopLocationsForMap {
    final list = <Map<String, dynamic>>[];
    if (shopPortions != null && shopPortions!.isNotEmpty) {
      for (final p in shopPortions!) {
        if (p.shopLat != null && p.shopLng != null) {
          list.add({
            'lat': p.shopLat!,
            'lng': p.shopLng!,
            'name': p.shopName,
          });
        }
      }
    } else if (shopLat != null && shopLng != null) {
      list.add({
        'lat': shopLat!,
        'lng': shopLng!,
        'name': shopName,
      });
    }
    return list;
  }

  /// نسخة من الطلب مع تحديث موقع السائق فقط (للتتبع المباشر).
  Order copyWithDriverLocation({double? driverLat, double? driverLng}) {
    return Order(
      id: id,
      shopId: shopId,
      shopName: shopName,
      shopLat: shopLat,
      shopLng: shopLng,
      items: items,
      shopPortions: shopPortions,
      totalPrice: totalPrice,
      deliveryFee: deliveryFee,
      status: status,
      notes: notes,
      notesAudioUrl: notesAudioUrl,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deliveryLat: deliveryLat,
      deliveryLng: deliveryLng,
      driverId: driverId,
      driverName: driverName,
      driverPhone: driverPhone,
      driverPhoto: driverPhoto,
      driverLat: driverLat ?? this.driverLat,
      driverLng: driverLng ?? this.driverLng,
      customerName: customerName,
      customerPhone: customerPhone,
    );
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final List<OrderItem> itemsList = rawItems is List
        ? (rawItems)
            .whereType<Map<String, dynamic>>()
            .map((e) => OrderItem.fromJson(e))
            .toList()
        : [];
    final rawPortions = json['shopPortions'];
    List<ShopPortion>? shopPortionsList;
    if (rawPortions is List && rawPortions.isNotEmpty) {
      shopPortionsList = rawPortions
          .whereType<Map<String, dynamic>>()
          .map((e) => ShopPortion.fromJson(e))
          .toList();
    }
    final shop = json['shopId'];
    String? shopName;
    String shopIdVal = '';
    double? shopLat;
    double? shopLng;
    if (shop is Map<String, dynamic>) {
      shopName = shop['name'] as String?;
      shopIdVal = (shop['_id'] ?? shop['id'])?.toString() ?? '';
      final loc = shop['location'];
      if (loc is Map<String, dynamic> && loc['coordinates'] is List) {
        final coords = loc['coordinates'] as List;
        if (coords.length >= 2) {
          final lng = (coords[0] is num) ? (coords[0] as num).toDouble() : null;
          final lat = (coords[1] is num) ? (coords[1] as num).toDouble() : null;
          if (lng != null && lat != null) {
            shopLng = lng;
            shopLat = lat;
          }
        }
      }
    } else if (shop != null) {
      shopIdVal = shop.toString();
    }
    if (shopPortionsList != null && shopPortionsList.isNotEmpty && shopIdVal.isEmpty) {
      shopIdVal = shopPortionsList.first.shopId;
      if (shopName == null && shopPortionsList.length == 1) {
        shopName = shopPortionsList.first.shopName;
      }
    }
    double? deliveryLat;
    double? deliveryLng;
    final loc = json['deliveryLocation'];
    if (loc is Map<String, dynamic> && loc['coordinates'] is List) {
      final coords = loc['coordinates'] as List;
      if (coords.length >= 2) {
        final lng = (coords[0] is num) ? (coords[0] as num).toDouble() : null;
        final lat = (coords[1] is num) ? (coords[1] as num).toDouble() : null;
        if (lng != null && lat != null) {
          deliveryLat = lat;
          deliveryLng = lng;
        }
      }
    }
    String? driverId;
    String? driverName;
    String? driverPhone;
    String? driverPhoto;
    double? driverLat;
    double? driverLng;
    final driver = json['driverId'];
    if (driver is Map<String, dynamic>) {
      driverId = (driver['_id'] ?? driver['id'])?.toString();
      driverName = driver['name'] as String?;
      driverPhone = driver['phone'] as String?;
      driverPhoto = driver['avatar'] as String?;
      final driverLoc = driver['location'];
      if (driverLoc is Map<String, dynamic> && driverLoc['coordinates'] is List) {
        final coords = driverLoc['coordinates'] as List;
        if (coords.length >= 2) {
          final lng = (coords[0] is num) ? (coords[0] as num).toDouble() : null;
          final lat = (coords[1] is num) ? (coords[1] as num).toDouble() : null;
          if (lng != null && lat != null) {
            driverLat = lat;
            driverLng = lng;
          }
        }
      }
    }
    String? customerName;
    String? customerPhone;
    final customer = json['customerId'];
    if (customer is Map<String, dynamic>) {
      customerName = customer['name'] as String?;
      customerPhone = customer['phone'] as String?;
    }
    return Order(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      shopId: shopIdVal.isNotEmpty ? shopIdVal : (json['shopId'] is Map ? (json['shopId'] as Map)['_id'] : json['shopId'])?.toString() ?? '',
      shopName: shopName ?? (json['shopName'] as String?),
      shopLat: shopLat,
      shopLng: shopLng,
      items: itemsList,
      shopPortions: shopPortionsList,
      totalPrice: (json['totalPrice'] is num) ? (json['totalPrice'] as num).toDouble() : 0,
      deliveryFee: (json['deliveryFee'] is num) ? (json['deliveryFee'] as num).toDouble() : 0,
      status: OrderStatus.fromValue((json['status'] ?? '').toString()) ?? OrderStatus.pending,
      notes: json['notes'] as String?,
      notesAudioUrl: json['notesAudioUrl'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
      deliveryLat: deliveryLat,
      deliveryLng: deliveryLng,
      driverId: driverId,
      driverName: driverName,
      driverPhone: driverPhone,
      driverPhoto: driverPhoto,
      driverLat: driverLat,
      driverLng: driverLng,
      customerName: customerName,
      customerPhone: customerPhone,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'shopId': shopId,
        'shopName': shopName,
        'items': items.map((e) => e.toJson()).toList(),
        'totalPrice': totalPrice,
        'deliveryFee': deliveryFee,
        'status': status.value,
        'notes': notes,
        'notesAudioUrl': notesAudioUrl,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        if (deliveryLat != null && deliveryLng != null)
          'deliveryLocation': {
            'type': 'Point',
            'coordinates': [deliveryLng, deliveryLat],
          },
      };
}
