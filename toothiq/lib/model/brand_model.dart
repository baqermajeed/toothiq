import '../core/utils/image_url.dart';
import 'product_model.dart';

class BrandModel {
  final String id;
  final String name;
  final String imageUrl;

  const BrandModel({
    required this.id,
    required this.name,
    this.imageUrl = '',
  });

  /// توافق مع الاستخدامات القديمة التي كانت تقرأ `logoAsset`.
  String get logoAsset => imageUrl;

  bool get hasImage => imageUrl.trim().isNotEmpty;

  factory BrandModel.fromJson(Map<String, dynamic> json) {
    return BrandModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['nameAr']?.toString() ?? json['name']?.toString() ?? '',
      imageUrl: ImageUrl.resolve(
        json['image']?.toString() ?? json['logo']?.toString() ?? json['logoAsset']?.toString(),
        fallback: '',
      ),
    );
  }

  BrandModel copyWith({
    String? id,
    String? name,
    String? imageUrl,
  }) {
    return BrandModel(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  static List<BrandModel> fromProducts(Iterable<ProductModel> products) {
    final brandsById = <String, BrandModel>{};

    for (final product in products) {
      final brandId = product.brandId?.trim();
      if (brandId == null || brandId.isEmpty) continue;

      final brandName = product.brandName?.trim();
      brandsById.putIfAbsent(
        brandId,
        () => BrandModel(
          id: brandId,
          name: (brandName != null && brandName.isNotEmpty)
              ? brandName
              : 'براند',
        ),
      );
    }

    return brandsById.values.toList(growable: false);
  }
}
