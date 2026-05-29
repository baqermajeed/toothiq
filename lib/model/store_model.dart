class StoreModel {
  static const String defaultLogoAsset = 'assets/images/stores/store_logo.png';

  final String id;
  final String name;
  final String description;
  final double rating;
  final String logoAsset;

  const StoreModel({
    required this.id,
    required this.name,
    required this.description,
    this.rating = 4.5,
    this.logoAsset = defaultLogoAsset,
  });
}
