class BrandModel {
  final String id;
  final String name;
  final String logoAsset;

  const BrandModel({
    required this.id,
    required this.name,
    this.logoAsset = 'assets/images/stores/store_logo.png',
  });
}
