import '../core/utils/image_url.dart';
import 'product_model.dart';

class BrandModel {
  final String id;
  final String name;
  final String logoAsset;

  const BrandModel({
    required this.id,
    required this.name,
    this.logoAsset = 'assets/images/stores/store_logo.png',
  });

  factory BrandModel.fromJson(Map<String, dynamic> json) {
    return BrandModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['nameAr']?.toString() ?? json['name']?.toString() ?? '',
      logoAsset: ImageUrl.resolve(
        json['image']?.toString() ?? json['logo']?.toString(),
        fallback: 'assets/images/stores/store_logo.png',
      ),
    );
  }

  static List<BrandModel> fromProducts(Iterable<ProductModel> products) {
    final brandsById = <String, BrandModel>{};

    for (final product in products) {
      final brandId = product.brandId?.trim();
      if (brandId == null || brandId.isEmpty) continue;

      final brandName = product.brandName?.trim();
      if (brandName == null || brandName.isEmpty) continue;

      brandsById.putIfAbsent(
        brandId,
        () => BrandModel(id: brandId, name: brandName),
      );
    }

    return brandsById.values.toList(growable: false);
  }
}
