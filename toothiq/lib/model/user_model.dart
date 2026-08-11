class UserModel {
  final String id;
  final String name;
  final String phone;
  final String governorateId;
  final String? clinicName;
  final double? locationLat;
  final double? locationLng;

  const UserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.governorateId,
    this.clinicName,
    this.locationLat,
    this.locationLng,
  });

  bool get hasLocation => locationLat != null && locationLng != null;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    double? lat;
    double? lng;
    final location = json['location'];
    if (location is Map<String, dynamic>) {
      final coords = location['coordinates'];
      if (coords is List && coords.length >= 2) {
        final coordLng = (coords[0] as num?)?.toDouble();
        final coordLat = (coords[1] as num?)?.toDouble();
        if (coordLat != null && coordLng != null) {
          lat = coordLat;
          lng = coordLng;
        }
      }
    }

    return UserModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      governorateId: json['governorateId']?.toString() ?? '',
      clinicName: json['clinicName']?.toString(),
      locationLat: lat,
      locationLng: lng,
    );
  }
}
