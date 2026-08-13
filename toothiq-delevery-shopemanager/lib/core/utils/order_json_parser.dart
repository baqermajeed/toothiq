abstract final class OrderJsonParser {
  static List<Map<String, dynamic>> lineItems(Map<String, dynamic> json) {
    final direct = json['items'];
    if (direct is List && direct.isNotEmpty) {
      return direct.whereType<Map<String, dynamic>>().toList(growable: false);
    }

    final portions = json['shopPortions'];
    if (portions is! List) return const [];

    final merged = <Map<String, dynamic>>[];
    for (final portion in portions.whereType<Map<String, dynamic>>()) {
      final portionItems = portion['items'];
      if (portionItems is List) {
        merged.addAll(portionItems.whereType<Map<String, dynamic>>());
      }
    }
    return merged;
  }

  static String? storeName(Map<String, dynamic> json) {
    final direct = json['shopName']?.toString().trim();
    if (direct != null && direct.isNotEmpty) return direct;

    final shop = shopMap(json);
    final name = shop?['name']?.toString().trim();
    if (name != null && name.isNotEmpty) return name;
    return null;
  }

  static String? shopId(Map<String, dynamic> json) {
    final shop = json['shopId'];
    if (shop is Map<String, dynamic>) {
      return shop['_id']?.toString() ?? shop['id']?.toString();
    }
    if (shop != null) return shop.toString();

    final portions = json['shopPortions'];
    if (portions is List && portions.isNotEmpty) {
      final first = portions.first;
      if (first is Map<String, dynamic>) {
        final shopRef = first['shopId'];
        if (shopRef is Map<String, dynamic>) {
          return shopRef['_id']?.toString() ?? shopRef['id']?.toString();
        }
        return shopRef?.toString();
      }
    }
    return null;
  }

  static Map<String, dynamic>? shopMap(Map<String, dynamic> json) {
    final shop = json['shopId'];
    if (shop is Map<String, dynamic>) return shop;

    final shopObj = json['shop'];
    if (shopObj is Map<String, dynamic>) return shopObj;

    final portions = json['shopPortions'];
    if (portions is List && portions.isNotEmpty) {
      final first = portions.first;
      if (first is Map<String, dynamic>) {
        final shopRef = first['shopId'];
        if (shopRef is Map<String, dynamic>) return shopRef;
      }
    }
    return null;
  }

  static int orderSubtotal(Map<String, dynamic> json) {
    for (final key in ['totalPrice', 'totalAmount', 'total']) {
      final value = (json[key] as num?)?.toInt();
      if (value != null && value > 0) return value;
    }

    var sum = 0;
    for (final item in lineItems(json)) {
      final price = lineItemUnitPrice(item);
      final qty = (item['quantity'] as num?)?.toInt() ?? 1;
      sum += price * qty;
    }
    return sum;
  }

  static int deliveryFee(Map<String, dynamic> json) {
    return (json['deliveryFee'] as num?)?.toInt() ?? 0;
  }

  static int lineItemUnitPrice(Map<String, dynamic> raw) {
    final product = raw['productId'];
    final productMap = product is Map<String, dynamic> ? product : null;

    for (final key in ['unitPrice', 'price', 'offerPrice']) {
      final direct = _readAmount(raw[key]);
      if (direct > 0) return direct;
    }

    if (productMap != null) {
      for (final key in ['offerPrice', 'price', 'unitPrice']) {
        final nested = _readAmount(productMap[key]);
        if (nested > 0) return nested;
      }
    }
    return 0;
  }

  static int _readAmount(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value.trim());
      if (parsed != null) return parsed;
      final asDouble = double.tryParse(value.trim());
      if (asDouble != null) return asDouble.toInt();
    }
    return 0;
  }

  static (double?, double?) readCoordinates(dynamic location) {
    if (location is! Map<String, dynamic>) return (null, null);
    final latDirect = location['lat'];
    final lngDirect = location['lng'];
    if (latDirect is num && lngDirect is num) {
      return (latDirect.toDouble(), lngDirect.toDouble());
    }
    final coords = location['coordinates'];
    if (coords is! List || coords.length < 2) return (null, null);
    final lng = (coords[0] is num) ? (coords[0] as num).toDouble() : null;
    final lat = (coords[1] is num) ? (coords[1] as num).toDouble() : null;
    return (lat, lng);
  }
}
