/// نتيجة التحقق من كون النقطة داخل منطقة طلب صوتي فقط.
class VoiceOrderZoneCheckResult {
  const VoiceOrderZoneCheckResult({
    required this.inside,
    this.zoneId,
    this.zoneName,
  });

  factory VoiceOrderZoneCheckResult.fromJson(Map<String, dynamic> json) {
    final zone = json['zone'];
    String? zoneId;
    String? zoneName;
    if (zone is Map<String, dynamic>) {
      zoneId = zone['id']?.toString();
      zoneName = zone['name'] as String?;
    }
    return VoiceOrderZoneCheckResult(
      inside: json['inside'] as bool? ?? false,
      zoneId: zoneId,
      zoneName: zoneName,
    );
  }

  final bool inside;
  final String? zoneId;
  final String? zoneName;
}
