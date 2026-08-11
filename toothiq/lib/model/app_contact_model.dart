class AppContactModel {
  final String facebookUrl;
  final String instagramUrl;
  final String supportPhone;
  final String aboutUs;
  final bool deliveryEnabled;
  final String deliveryPauseReason;
  final int globalDeliveryFee;

  const AppContactModel({
    this.facebookUrl = '',
    this.instagramUrl = '',
    this.supportPhone = '',
    this.aboutUs = '',
    this.deliveryEnabled = true,
    this.deliveryPauseReason = '',
    this.globalDeliveryFee = 0,
  });

  static const empty = AppContactModel();

  AppContactModel copyWith({
    String? facebookUrl,
    String? instagramUrl,
    String? supportPhone,
    String? aboutUs,
    bool? deliveryEnabled,
    String? deliveryPauseReason,
    int? globalDeliveryFee,
  }) {
    return AppContactModel(
      facebookUrl: facebookUrl ?? this.facebookUrl,
      instagramUrl: instagramUrl ?? this.instagramUrl,
      supportPhone: supportPhone ?? this.supportPhone,
      aboutUs: aboutUs ?? this.aboutUs,
      deliveryEnabled: deliveryEnabled ?? this.deliveryEnabled,
      deliveryPauseReason: deliveryPauseReason ?? this.deliveryPauseReason,
      globalDeliveryFee: globalDeliveryFee ?? this.globalDeliveryFee,
    );
  }

  factory AppContactModel.fromJson(Map<String, dynamic> json) {
    return AppContactModel(
      facebookUrl: json['facebookUrl']?.toString().trim() ?? '',
      instagramUrl: json['instagramUrl']?.toString().trim() ?? '',
      supportPhone: json['supportPhone']?.toString().trim() ?? '',
      aboutUs: json['aboutUs']?.toString().trim() ?? '',
      deliveryEnabled: json['deliveryEnabled'] as bool? ?? true,
      deliveryPauseReason: json['deliveryPauseReason']?.toString().trim() ?? '',
      globalDeliveryFee: _readFee(json),
    );
  }

  static int _readFee(Map<String, dynamic> json) {
    final raw = json['globalDeliveryFee'] ??
        json['unifiedDeliveryFee'] ??
        json['deliveryFee'] ??
        json['defaultDeliveryFee'] ??
        (json['delivery'] is Map<String, dynamic>
            ? (json['delivery'] as Map<String, dynamic>)['fee']
            : null) ??
        (json['deliverySettings'] is Map<String, dynamic>
            ? (json['deliverySettings'] as Map<String, dynamic>)['fee']
            : null);
    return _toInt(raw);
  }

  static int readDeliveryFee(Map<String, dynamic> json) => _readFee(json);

  static int _toInt(dynamic raw) {
    if (raw is num) return raw.round();
    if (raw == null) return 0;

    final normalized = raw
        .toString()
        .replaceAll(RegExp(r'[^0-9\-]'), '')
        .trim();
    if (normalized.isEmpty) return 0;
    return int.tryParse(normalized) ?? 0;
  }

  String formatDeliveryFeeLabel() {
    if (globalDeliveryFee <= 0) return 'مجاني';
    return '${_formatNumber(globalDeliveryFee)} د.ع';
  }

  static String _formatNumber(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }
}
