/// بيانات التواصل المعروضة في صفحة الملف الشخصي (فيسبوك، انستغرام، واتساب الدعم).
class ContactInfo {
  const ContactInfo({
    this.facebookUrl = '',
    this.instagramUrl = '',
    this.supportPhone = '',
  });

  final String facebookUrl;
  final String instagramUrl;
  final String supportPhone;

  factory ContactInfo.fromJson(Map<String, dynamic> json) {
    return ContactInfo(
      facebookUrl: (json['facebookUrl'] as String?)?.trim() ?? '',
      instagramUrl: (json['instagramUrl'] as String?)?.trim() ?? '',
      supportPhone: (json['supportPhone'] as String?)?.trim() ?? '',
    );
  }

  static const empty = ContactInfo();
}
