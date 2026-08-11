class DeliveryAddressModel {
  final String id;
  final String governorate;
  final String area;
  final String landmark;
  final bool isCurrent;
  final double? lat;
  final double? lng;

  const DeliveryAddressModel({
    required this.id,
    required this.governorate,
    required this.area,
    required this.landmark,
    this.isCurrent = false,
    this.lat,
    this.lng,
  });

  bool get hasCoordinates => lat != null && lng != null;

  String get displayTitle => area;

  String get displaySubtitle {
    if (hasCoordinates) {
      return '$landmark • موقع محدد على الخريطة';
    }
    return landmark;
  }

  String get formattedLine {
    return [
      governorate.trim(),
      area.trim(),
      landmark.trim(),
    ].where((part) => part.isNotEmpty).join(' ، ');
  }

  DeliveryAddressModel copyWith({
    String? id,
    String? governorate,
    String? area,
    String? landmark,
    bool? isCurrent,
    double? lat,
    double? lng,
  }) {
    return DeliveryAddressModel(
      id: id ?? this.id,
      governorate: governorate ?? this.governorate,
      area: area ?? this.area,
      landmark: landmark ?? this.landmark,
      isCurrent: isCurrent ?? this.isCurrent,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'governorate': governorate,
        'area': area,
        'landmark': landmark,
        'isCurrent': isCurrent,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      };

  factory DeliveryAddressModel.fromJson(Map<String, dynamic> json) {
    return DeliveryAddressModel(
      id: json['id']?.toString() ?? '',
      governorate: json['governorate'] as String? ??
          json['label'] as String? ??
          '',
      area: json['area'] as String? ?? json['label'] as String? ?? '',
      landmark: json['landmark'] as String? ?? json['street'] as String? ?? '',
      isCurrent: json['isCurrent'] as bool? ?? false,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
    );
  }
}
