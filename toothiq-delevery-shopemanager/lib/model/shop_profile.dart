class ShopProfile {
  final String id;
  final String name;
  final String description;
  final String address;
  final String phonePrimary;
  final String? phoneSecondary;
  final String? logoPath;

  const ShopProfile({
    required this.id,
    required this.name,
    this.description = '',
    this.address = '',
    this.phonePrimary = '',
    this.phoneSecondary,
    this.logoPath,
  });

  bool get hasLogo => logoPath != null && logoPath!.isNotEmpty;

  int get completionPercent {
    var filled = 0;
    const total = 6;
    if (name.trim().isNotEmpty) filled++;
    if (description.trim().isNotEmpty) filled++;
    if (address.trim().isNotEmpty) filled++;
    if (phonePrimary.trim().isNotEmpty) filled++;
    if (phoneSecondary?.trim().isNotEmpty == true) filled++;
    if (hasLogo) filled++;
    return ((filled / total) * 100).round();
  }

  ShopProfile copyWith({
    String? name,
    String? description,
    String? address,
    String? phonePrimary,
    String? phoneSecondary,
    String? logoPath,
    bool clearSecondaryPhone = false,
    bool clearLogo = false,
  }) {
    return ShopProfile(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      phonePrimary: phonePrimary ?? this.phonePrimary,
      phoneSecondary: clearSecondaryPhone
          ? null
          : (phoneSecondary ?? this.phoneSecondary),
      logoPath: clearLogo ? null : (logoPath ?? this.logoPath),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'address': address,
        'phonePrimary': phonePrimary,
        'phoneSecondary': phoneSecondary,
        'logoPath': logoPath,
      };

  factory ShopProfile.fromJson(Map<String, dynamic> json) {
    return ShopProfile(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      phonePrimary: json['phonePrimary']?.toString() ?? '',
      phoneSecondary: json['phoneSecondary']?.toString(),
      logoPath: json['logoPath']?.toString(),
    );
  }

  factory ShopProfile.fromApi(Map<String, dynamic> json) {
    final id = json['_id']?.toString() ?? json['id']?.toString() ?? '';
    final logo = json['logo']?.toString() ??
        json['image']?.toString() ??
        json['avatar']?.toString();

    var address = '';
    final location = json['location'];
    if (location is Map<String, dynamic>) {
      address = location['address']?.toString() ??
          location['governorate']?.toString() ??
          '';
    }

    final phones = json['phones'];
    String? phone2;
    if (phones is List && phones.length > 1) {
      phone2 = phones[1]?.toString();
    }

    return ShopProfile(
      id: id,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      address: address,
      phonePrimary: json['phone']?.toString() ?? json['phonePrimary']?.toString() ?? '',
      phoneSecondary: json['phone2']?.toString() ?? phone2,
      logoPath: logo,
    );
  }
}
