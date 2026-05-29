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

  const ProductModel({
    required this.id,
    required this.name,
    required this.storeName,
    required this.description,
    required this.price,
    required this.imageAsset,
    this.fullDescription = '',
    this.galleryAssets = const [],
    this.expirationDate = '1 / 5 / 2026',
    this.isFavorite = false,
  });

  List<String> get images {
    if (galleryAssets.isNotEmpty) return galleryAssets;
    return [imageAsset, imageAsset, imageAsset, imageAsset];
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
