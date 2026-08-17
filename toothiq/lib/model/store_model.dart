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
  final String? openHoursFrom;
  final String? openHoursTo;
  final String? governorate;

  const StoreModel({
    required this.id,
    required this.name,
    required this.description,
    this.aboutDescription = '',
    this.address = '',
    this.rating = 0,
    this.logoAsset = defaultLogoAsset,
    this.openHoursFrom,
    this.openHoursTo,
    this.governorate,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    final logo = json['logo']?.toString() ??
        json['image']?.toString() ??
        json['avatar']?.toString();

    return StoreModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      aboutDescription: json['description']?.toString().trim() ?? '',
      address: _addressFromJson(json),
      rating: (json['rating'] as num?)?.toDouble() ??
          (json['avgRating'] as num?)?.toDouble() ??
          0,
      logoAsset: (logo == null || logo.isEmpty) ? defaultLogoAsset : logo,
      openHoursFrom: _hourPart(json['openHours'], 'from'),
      openHoursTo: _hourPart(json['openHours'], 'to'),
      governorate: _governorateFromJson(json),
    );
  }

  StoreModel copyWith({
    String? name,
    String? description,
    String? aboutDescription,
    String? address,
    double? rating,
    String? logoAsset,
    String? openHoursFrom,
    String? openHoursTo,
    String? governorate,
  }) {
    return StoreModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      aboutDescription: aboutDescription ?? this.aboutDescription,
      address: address ?? this.address,
      rating: rating ?? this.rating,
      logoAsset: logoAsset ?? this.logoAsset,
      openHoursFrom: openHoursFrom ?? this.openHoursFrom,
      openHoursTo: openHoursTo ?? this.openHoursTo,
      governorate: governorate ?? this.governorate,
    );
  }

  String get workingHoursText {
    final from = openHoursFrom?.trim() ?? '';
    final to = openHoursTo?.trim() ?? '';
    if (from.isEmpty && to.isEmpty) return '24 ساعة';
    if (from.isEmpty) return 'حتى $to';
    if (to.isEmpty) return 'من $from';
    return '$from - $to';
  }

  String get deliveryHoursText => '45 د - ساعة';

  String get governorateDisplay {
    final named = governorate?.trim();
    if (named != null && named.isNotEmpty) return named;
    final line = address.trim();
    return line.split(RegExp(r'[،,]')).first.trim();
  }

  static String _addressFromLocation(dynamic location) {
    if (location is! Map) return '';
    final address = location['address']?.toString();
    if (address != null && address.isNotEmpty) return address;
    final governorate = location['governorate']?.toString();
    if (governorate != null && governorate.isNotEmpty) return governorate;
    return '';
  }

  static String _hourPart(dynamic hours, String key) {
    if (hours is! Map) return '';
    final value = hours[key];
    if (value == null) return '';
    return value.toString().trim();
  }

  static String _addressFromJson(Map<String, dynamic> json) {
    final top = json['address']?.toString().trim();
    if (top != null && top.isNotEmpty) return top;
    return _addressFromLocation(json['location']);
  }

  static String? _namedValue(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      final text = value.trim();
      return text.isEmpty ? null : text;
    }
    if (value is Map) {
      final name = value['nameAr']?.toString().trim() ??
          value['name']?.toString().trim() ??
          value['title']?.toString().trim();
      if (name != null && name.isNotEmpty) return name;
    }
    return null;
  }

  static String? _governorateFromJson(Map<String, dynamic> json) {
    final loc = json['location'];
    if (loc is Map) {
      final fromLoc = _namedValue(loc['governorate']);
      if (fromLoc != null) return fromLoc;
    }
    return _namedValue(json['governorate']);
  }
}
