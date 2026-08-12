import 'brand_model.dart';
import 'category_section_model.dart';

class ShopCategoryModel {
  final String id;
  final String nameAr;
  final String? iconUrl;
  final List<CategorySectionModel> sections;
  final List<BrandModel> brands;
  final String source;
  final String? shopId;
  final String? parentCategoryId;

  const ShopCategoryModel({
    required this.id,
    required this.nameAr,
    this.iconUrl,
    this.sections = const [],
    this.brands = const [],
    this.source = 'admin',
    this.shopId,
    this.parentCategoryId,
  });

  bool get isShopCategory => source == 'shop';

  factory ShopCategoryModel.fromJson(Map<String, dynamic> json) {
    final sections = [
      ..._parseSections(json['sections']),
      ..._parseSections(json['subcategories']),
    ];
    final brands = [
      ..._parseBrands(json['brands']),
      ...brandsFromSections(json['sections']),
      ...brandsFromSections(json['subcategories']),
    ];

    return ShopCategoryModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      nameAr: json['nameAr']?.toString() ?? json['name']?.toString() ?? '',
      iconUrl: _readIconUrl(json),
      sections: sections,
      brands: brands,
      source: json['source']?.toString() ?? 'admin',
      shopId: json['shopId']?.toString(),
      parentCategoryId: json['parentCategoryId']?.toString(),
    );
  }

  static List<CategorySectionModel> _parseSections(dynamic raw) {
    if (raw is! List) return const [];
    final sections = <CategorySectionModel>[];
    for (final item in raw.whereType<Map<String, dynamic>>()) {
      if (_isBrandType(item['type']?.toString())) continue;
      final section = CategorySectionModel.fromJson(item);
      if (section.id.isNotEmpty && section.nameAr.isNotEmpty) {
        sections.add(section);
      }
    }
    return sections;
  }

  static List<BrandModel> _parseBrands(dynamic raw) {
    if (raw is! List) return const [];
    final brands = <BrandModel>[];
    for (final item in raw.whereType<Map<String, dynamic>>()) {
      final brand = BrandModel.fromJson(item);
      if (brand.id.isNotEmpty && brand.name.isNotEmpty) {
        brands.add(brand);
      }
    }
    return brands;
  }

  static List<BrandModel> brandsFromSections(dynamic raw) {
    if (raw is! List) return const [];
    final brands = <BrandModel>[];
    for (final item in raw.whereType<Map<String, dynamic>>()) {
      if (!_isBrandType(item['type']?.toString())) continue;
      final brand = BrandModel.fromJson(item);
      if (brand.id.isNotEmpty && brand.name.isNotEmpty) {
        brands.add(brand);
      }
    }
    return brands;
  }

  static String? _readIconUrl(Map<String, dynamic> json) {
    for (final key in ['icon', 'image']) {
      final value = json[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  static bool _isBrandType(String? type) {
    final value = type?.trim().toLowerCase();
    return value == 'brand' || value == 'براند';
  }
}
