class StoreModel {
  static const String defaultLogoAsset = 'assets/images/stores/store_logo.png';

  static const String defaultAboutDescription =
      'متجر متخصص بتوفير احتياجات أطباء الأسنان من الأدوات والمستلزمات الطبية. عندنا تجد كل اللي تحتاجه من مواد الحشوات والتبييض وأدوات المعاينة، بجودة عالية وضمان الأصالة';

  final String id;
  final String name;
  final String description;
  final String aboutDescription;
  final String address;
  final double rating;
  final String logoAsset;

  const StoreModel({
    required this.id,
    required this.name,
    required this.description,
    this.aboutDescription = defaultAboutDescription,
    this.address = 'بابل ، شارع 40',
    this.rating = 4.5,
    this.logoAsset = defaultLogoAsset,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    final logo = json['logo']?.toString() ??
        json['image']?.toString() ??
        json['avatar']?.toString();

    return StoreModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      aboutDescription: json['description']?.toString().isNotEmpty == true
          ? json['description'].toString()
          : defaultAboutDescription,
      address: _addressFromLocation(json['location']),
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      logoAsset: (logo == null || logo.isEmpty) ? defaultLogoAsset : logo,
    );
  }

  static String _addressFromLocation(dynamic location) {
    if (location is! Map<String, dynamic>) return 'العراق';
    final address = location['address']?.toString();
    if (address != null && address.isNotEmpty) return address;
    final governorate = location['governorate']?.toString();
    if (governorate != null && governorate.isNotEmpty) return governorate;
    return 'العراق';
  }
}
