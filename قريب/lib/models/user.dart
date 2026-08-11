/// نموذج المستخدم كما يعيده الـ API (بدون passwordHash و refreshTokenHash).
class User {
  const User({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.avatar,
    required this.roles,
    this.location,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      avatar: json['avatar'] as String?,
      roles: List<String>.from(json['roles'] as List? ?? []),
      location: json['location'] != null
          ? (json['location'] as Map<String, dynamic>)
          : null,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  final String id;
  final String name;
  final String phone;
  final String? email;
  /// صورة المستخدم (مسار من API مثل /uploads/users/xxx). اختياري.
  final String? avatar;
  final List<String> roles;
  final Map<String, dynamic>? location;
  /// هل لدى المستخدم موقع صالح (إحداثيات محفوظة)؟
  bool get hasValidLocation {
    final loc = location;
    if (loc == null) return false;
    final coords = loc['coordinates'];
    if (coords is! List || coords.length < 2) return false;
    return true;
  }
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'phone': phone,
        if (email != null) 'email': email,
        if (avatar != null) 'avatar': avatar,
        'roles': roles,
        if (location != null) 'location': location,
        'isActive': isActive,
        if (createdAt != null) 'createdAt': createdAt?.toIso8601String(),
        if (updatedAt != null) 'updatedAt': updatedAt?.toIso8601String(),
      };
}
