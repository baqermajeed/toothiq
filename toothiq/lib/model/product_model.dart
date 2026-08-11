import '../../core/utils/image_url.dart';

class ProductModel {
  final String id;
  final String name;
  final String storeName;
  final String description;
  final String fullDescription;
  final int price;
  final String imageAsset;
  final List<String> galleryAssets;
  final String expirationDate;
  final bool isFavorite;
  final String? shopId;
  final String? productCategoryId;
  final String? brandId;
  final String? brandName;

  const ProductModel({
    required this.id,
    required this.name,
    required this.storeName,
    required this.description,
    required this.price,
    required this.imageAsset,
    this.fullDescription = '',
    this.galleryAssets = const [],
    this.expirationDate = '',
    this.isFavorite = false,
    this.shopId,
    this.productCategoryId,
    this.brandId,
    this.brandName,
  });

  static String? _readBrandName(Map<String, dynamic> json) {
    final direct = json['brandName']?.toString().trim();
    if (direct != null && direct.isNotEmpty) return direct;

    final brand = json['brand'];
    if (brand is Map<String, dynamic>) {
      final nested =
          brand['nameAr']?.toString().trim() ?? brand['name']?.toString().trim();
      if (nested != null && nested.isNotEmpty) return nested;
    }

    return null;
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final priceValue = json['offerPrice'] ?? json['price'];
    final image = ImageUrl.resolve(
      json['image']?.toString(),
      fallback: ImageUrl.productPlaceholder,
    );

    return ProductModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      storeName: json['shopName']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      fullDescription: json['description']?.toString() ?? '',
      price: (priceValue as num?)?.toInt() ?? 0,
      imageAsset: image,
      galleryAssets: [image],
      expirationDate: _formatDate(json['expiryDate']),
      shopId: json['shopId']?.toString(),
      productCategoryId:
          json['categoryId']?.toString() ??
          json['productCategoryId']?.toString(),
      brandId: json['brandId']?.toString(),
      brandName: _readBrandName(json),
    );
  }

  factory ProductModel.fromShopJson(
    Map<String, dynamic> json, {
    required String shopId,
    required String shopName,
  }) {
    final priceValue = json['offerPrice'] ?? json['price'];
    final image = ImageUrl.resolve(
      json['image']?.toString(),
      fallback: ImageUrl.productPlaceholder,
    );

    return ProductModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      storeName: shopName,
      description: json['description']?.toString() ?? '',
      fullDescription: json['description']?.toString() ?? '',
      price: (priceValue as num?)?.toInt() ?? 0,
      imageAsset: image,
      galleryAssets: [image],
      expirationDate: _formatDate(json['expiryDate']),
      shopId: shopId,
      productCategoryId:
          json['categoryId']?.toString() ??
          json['productCategoryId']?.toString(),
      brandId: json['brandId']?.toString(),
      brandName: _readBrandName(json),
    );
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
      imageAsset: imageAsset,
      galleryAssets: galleryAssets,
      expirationDate: expirationDate,
      isFavorite: isFavorite ?? this.isFavorite,
      shopId: shopId,
      productCategoryId: productCategoryId,
      brandId: brandId,
      brandName: brandName,
    );
  }

  String get formattedPrice {
    final formatted = price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '$formatted د.ع';
  }
}
