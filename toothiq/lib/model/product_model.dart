import '../../core/utils/image_url.dart';

class ProductModel {
  final String id;
  final String name;
  final String storeName;
  final String description;
  final String fullDescription;
  final int price;
  final int? offerPrice;
  final bool isOnOffer;
  final String imageAsset;
  final List<String> galleryAssets;
  final String expirationDate;
  final bool isFavorite;
  final String? shopId;
  final String? productCategoryId;
  final String? subcategoryId;
  final String? subcategoryName;
  final String? brandId;
  final String? brandName;

  const ProductModel({
    required this.id,
    required this.name,
    required this.storeName,
    required this.description,
    required this.price,
    this.offerPrice,
    this.isOnOffer = false,
    required this.imageAsset,
    this.fullDescription = '',
    this.galleryAssets = const [],
    this.expirationDate = '',
    this.isFavorite = false,
    this.shopId,
    this.productCategoryId,
    this.subcategoryId,
    this.subcategoryName,
    this.brandId,
    this.brandName,
  });

  static String? _readRefId(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value['_id']?.toString() ?? value['id']?.toString();
    }
    final raw = value?.toString().trim();
    if (raw == null || raw.isEmpty) return null;
    return raw;
  }

  static String? _readBrandName(Map<String, dynamic> json) {
    final direct = json['brandName']?.toString().trim();
    if (direct != null && direct.isNotEmpty) return direct;

    final brand = json['brand'];
    if (brand is Map<String, dynamic>) {
      final nested =
          brand['nameAr']?.toString().trim() ?? brand['name']?.toString().trim();
      if (nested != null && nested.isNotEmpty) return nested;
    }

    final brandRef = json['brandId'];
    if (brandRef is Map<String, dynamic>) {
      final nested = brandRef['nameAr']?.toString().trim() ??
          brandRef['name']?.toString().trim();
      if (nested != null && nested.isNotEmpty) return nested;
    }

    return null;
  }

  static String? _readSubcategoryName(Map<String, dynamic> json) {
    final direct = json['subcategoryName']?.toString().trim();
    if (direct != null && direct.isNotEmpty) return direct;

    final subcategory = json['subcategory'];
    if (subcategory is Map<String, dynamic>) {
      final nested = subcategory['nameAr']?.toString().trim() ??
          subcategory['name']?.toString().trim();
      if (nested != null && nested.isNotEmpty) return nested;
    }

    final subcategoryRef = json['subcategoryId'];
    if (subcategoryRef is Map<String, dynamic>) {
      final nested = subcategoryRef['nameAr']?.toString().trim() ??
          subcategoryRef['name']?.toString().trim();
      if (nested != null && nested.isNotEmpty) return nested;
    }

    return null;
  }

  static int? _readInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static ({int price, int? offerPrice, bool isOnOffer}) _readPrices(
    Map<String, dynamic> json,
  ) {
    final price = _readInt(json['price']) ?? 0;
    final offer = _readInt(json['offerPrice']);
    var onOffer = json['isOnOffer'] == true;
    if (json['isOnOffer'] == null) {
      onOffer = offer != null && offer > 0 && offer < price;
      final ends = json['offerEndsAt']?.toString();
      if (onOffer && ends != null && ends.isNotEmpty) {
        final parsed = DateTime.tryParse(ends);
        if (parsed != null && !parsed.isAfter(DateTime.now())) {
          onOffer = false;
        }
      }
    }
    return (price: price, offerPrice: offer, isOnOffer: onOffer);
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final prices = _readPrices(json);
    final gallery = _readGallery(json);
    final image = gallery.isNotEmpty
        ? gallery.first
        : ImageUrl.resolve(
            json['image']?.toString(),
            fallback: ImageUrl.productPlaceholder,
          );

    return ProductModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      storeName: json['shopName']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      fullDescription: json['description']?.toString() ?? '',
      price: prices.price,
      offerPrice: prices.offerPrice,
      isOnOffer: prices.isOnOffer,
      imageAsset: image,
      galleryAssets: gallery,
      expirationDate: _formatDate(json['expiryDate']),
      shopId: json['shopId']?.toString(),
      productCategoryId: _readRefId(json['productCategoryId']) ??
          _readRefId(json['categoryId']),
      subcategoryId: _readRefId(json['subcategoryId']),
      subcategoryName: _readSubcategoryName(json),
      brandId: _readRefId(json['brandId']),
      brandName: _readBrandName(json),
    );
  }

  factory ProductModel.fromShopJson(
    Map<String, dynamic> json, {
    required String shopId,
    required String shopName,
  }) {
    final prices = _readPrices(json);
    final gallery = _readGallery(json);
    final image = gallery.isNotEmpty
        ? gallery.first
        : ImageUrl.resolve(
            json['image']?.toString(),
            fallback: ImageUrl.productPlaceholder,
          );

    return ProductModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      storeName: shopName,
      description: json['description']?.toString() ?? '',
      fullDescription: json['description']?.toString() ?? '',
      price: prices.price,
      offerPrice: prices.offerPrice,
      isOnOffer: prices.isOnOffer,
      imageAsset: image,
      galleryAssets: gallery,
      expirationDate: _formatDate(json['expiryDate']),
      shopId: shopId,
      productCategoryId: _readRefId(json['productCategoryId']) ??
          _readRefId(json['categoryId']),
      subcategoryId: _readRefId(json['subcategoryId']),
      subcategoryName: _readSubcategoryName(json),
      brandId: _readRefId(json['brandId']),
      brandName: _readBrandName(json),
    );
  }

  static List<String> _readGallery(Map<String, dynamic> json) {
    final raw = json['images'] ?? json['gallery'] ?? json['galleryAssets'];
    final urls = <String>[];

    if (raw is List) {
      for (final item in raw) {
        final resolved = ImageUrl.resolve(
          item?.toString(),
          fallback: '',
        );
        if (resolved.isNotEmpty && !urls.contains(resolved)) {
          urls.add(resolved);
        }
      }
    }

    final primary = ImageUrl.resolve(
      json['image']?.toString(),
      fallback: '',
    );
    if (primary.isNotEmpty && !urls.contains(primary)) {
      urls.insert(0, primary);
    }

    if (urls.isEmpty) {
      return [ImageUrl.productPlaceholder];
    }
    return List<String>.unmodifiable(urls);
  }

  static String _formatDate(dynamic value) {
    if (value == null) return '';
    final raw = value.toString();
    if (raw.isEmpty) return '';
    final date = DateTime.tryParse(raw);
    if (date == null) return raw;
    return '${date.day} / ${date.month} / ${date.year}';
  }

  List<String> get images {
    if (galleryAssets.isNotEmpty) return galleryAssets;
    return [imageAsset];
  }

  String get detailsDescription {
    if (fullDescription.isNotEmpty) return fullDescription;
    return description;
  }

  ProductModel copyWith({bool? isFavorite}) {
    return ProductModel(
      id: id,
      name: name,
      storeName: storeName,
      description: description,
      fullDescription: fullDescription,
      price: price,
      offerPrice: offerPrice,
      isOnOffer: isOnOffer,
      imageAsset: imageAsset,
      galleryAssets: galleryAssets,
      expirationDate: expirationDate,
      isFavorite: isFavorite ?? this.isFavorite,
      shopId: shopId,
      productCategoryId: productCategoryId,
      subcategoryId: subcategoryId,
      subcategoryName: subcategoryName,
      brandId: brandId,
      brandName: brandName,
    );
  }

  Map<String, dynamic> toFavoriteJson() {
    return {
      'id': id,
      'name': name,
      'storeName': storeName,
      'description': description,
      'fullDescription': fullDescription,
      'price': price,
      'offerPrice': offerPrice,
      'isOnOffer': isOnOffer,
      'imageAsset': imageAsset,
      'galleryAssets': galleryAssets,
      'expirationDate': expirationDate,
      'shopId': shopId,
      'productCategoryId': productCategoryId,
      'subcategoryId': subcategoryId,
      'subcategoryName': subcategoryName,
      'brandId': brandId,
      'brandName': brandName,
      'isFavorite': true,
    };
  }

  factory ProductModel.fromFavoriteJson(Map<String, dynamic> json) {
    final gallery = json['galleryAssets'];
    return ProductModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      storeName: json['storeName']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      fullDescription: json['fullDescription']?.toString() ?? '',
      price: (json['price'] as num?)?.toInt() ?? 0,
      offerPrice: (json['offerPrice'] as num?)?.toInt(),
      isOnOffer: json['isOnOffer'] == true,
      imageAsset: json['imageAsset']?.toString() ?? ImageUrl.productPlaceholder,
      galleryAssets: gallery is List
          ? gallery.map((item) => item.toString()).toList(growable: false)
          : const [],
      expirationDate: json['expirationDate']?.toString() ?? '',
      isFavorite: true,
      shopId: json['shopId']?.toString(),
      productCategoryId: json['productCategoryId']?.toString(),
      subcategoryId: json['subcategoryId']?.toString(),
      subcategoryName: json['subcategoryName']?.toString(),
      brandId: json['brandId']?.toString(),
      brandName: json['brandName']?.toString(),
    );
  }

  int get sellingPrice {
    final offer = offerPrice;
    if (isOnOffer && offer != null && offer > 0) return offer;
    return price;
  }

  String get formattedPrice {
    final formatted = sellingPrice.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '$formatted د.ع';
  }

  String get formattedOriginalPrice {
    final formatted = price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '$formatted د.ع';
  }
}
