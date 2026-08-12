import '../core/utils/expiry_date_utils.dart';

class ShopProduct {
  final String id;
  final String name;
  final String description;
  final int price;
  final int stock;
  final String? imagePath;
  final List<String> galleryPaths;
  final String? categoryId;
  final String? categoryName;
  final String? brandId;
  final String? brandName;
  final String? expiryDate;
  final String? origin;
  final bool isAvailable;

  const ShopProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    this.imagePath,
    this.galleryPaths = const [],
    this.categoryId,
    this.categoryName,
    this.brandId,
    this.brandName,
    this.expiryDate,
    this.origin,
    this.isAvailable = true,
  });

  String? get primaryImage {
    if (imagePath != null && imagePath!.isNotEmpty) return imagePath;
    if (galleryPaths.isNotEmpty) return galleryPaths.first;
    return null;
  }

  List<String> get allImages {
    final images = <String>[];
    void add(String? value) {
      final path = value?.trim();
      if (path != null && path.isNotEmpty && !images.contains(path)) {
        images.add(path);
      }
    }

    add(imagePath);
    for (final path in galleryPaths) {
      add(path);
    }
    return images;
  }

  String get formattedPrice {
    final formatted = price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '$formatted د.ع';
  }

  ShopProduct copyWith({
    String? name,
    String? description,
    int? price,
    int? stock,
    String? imagePath,
    List<String>? galleryPaths,
    String? categoryId,
    String? categoryName,
    String? brandId,
    String? brandName,
    String? expiryDate,
    String? origin,
    bool? isAvailable,
    bool clearImage = false,
    bool clearCategory = false,
    bool clearBrand = false,
    bool clearExpiry = false,
    bool clearOrigin = false,
  }) {
    return ShopProduct(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      imagePath: clearImage ? null : (imagePath ?? this.imagePath),
      galleryPaths: galleryPaths ?? this.galleryPaths,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      categoryName: clearCategory ? null : (categoryName ?? this.categoryName),
      brandId: clearBrand ? null : (brandId ?? this.brandId),
      brandName: clearBrand ? null : (brandName ?? this.brandName),
      expiryDate: clearExpiry ? null : (expiryDate ?? this.expiryDate),
      origin: clearOrigin ? null : (origin ?? this.origin),
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  static String? _readRefId(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value['_id']?.toString() ?? value['id']?.toString();
    }
    final raw = value?.toString().trim();
    if (raw == null || raw.isEmpty) return null;
    return raw;
  }

  static String? _readName(Map<String, dynamic> json, String key) {
    final direct = json['${key}Name']?.toString().trim();
    if (direct != null && direct.isNotEmpty) return direct;
    final ref = json[key];
    if (ref is Map<String, dynamic>) {
      return ref['nameAr']?.toString() ?? ref['name']?.toString();
    }
    return null;
  }

  factory ShopProduct.fromApi(Map<String, dynamic> json) {
    final priceValue = json['offerPrice'] ?? json['price'];
    final gallery = _readGallery(json);
    final image = json['image']?.toString() ??
        json['imageUrl']?.toString() ??
        json['thumbnail']?.toString() ??
        (gallery.isNotEmpty ? gallery.first : null);
    final isAvailable = json['isAvailable'] != false && json['isActive'] != false;

    return ShopProduct(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: (priceValue as num?)?.toInt() ?? _readInt(priceValue) ?? 0,
      stock: _readStock(json),
      imagePath: image,
      galleryPaths: gallery,
      categoryId: _readRefId(json['categoryId']) ??
          _readRefId(json['productCategoryId']),
      categoryName: _readName(json, 'category') ??
          _readName(json, 'productCategory'),
      brandId: _readRefId(json['brandId']),
      brandName: _readName(json, 'brand'),
      expiryDate: ExpiryDateUtils.toDisplayValue(json['expiryDate']?.toString()) ??
          json['expiryDate']?.toString(),
      origin: json['origin']?.toString() ?? json['madeIn']?.toString(),
      isAvailable: isAvailable,
    );
  }

  static List<String> _readGallery(Map<String, dynamic> json) {
    final raw = json['images'] ?? json['gallery'] ?? json['galleryAssets'];
    final gallery = <String>[];
    if (raw is List) {
      for (final item in raw) {
        final path = _readImageValue(item);
        if (path != null && path.isNotEmpty && !gallery.contains(path)) {
          gallery.add(path);
        }
      }
    }
    return gallery;
  }

  static String? _readImageValue(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value['url']?.toString() ??
          value['path']?.toString() ??
          value['image']?.toString();
    }
    final raw = value?.toString().trim();
    if (raw == null || raw.isEmpty) return null;
    return raw;
  }

  static int _readStock(Map<String, dynamic> json) {
    for (final key in const [
      'stock',
      'quantity',
      'qty',
      'availableStock',
      'inventory',
    ]) {
      final value = _readInt(json[key]);
      if (value != null) return value;
    }
    return 0;
  }

  static int? _readInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  Map<String, dynamic> toApiBody() {
    final apiExpiry = ExpiryDateUtils.toApiValue(expiryDate);
    return {
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'quantity': stock,
      if (categoryId != null) 'productCategoryId': categoryId,
      if (brandId != null) 'brandId': brandId,
      if (apiExpiry != null) 'expiryDate': apiExpiry,
      if (origin != null && origin!.trim().isNotEmpty) 'origin': origin!.trim(),
      'isAvailable': isAvailable,
    };
  }
}
