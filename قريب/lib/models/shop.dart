/// نموذج المحل — يُنشأ من استجابة API (عنصر من items أو data).
class Shop {
  const Shop({
    required this.id,
    required this.name,
    required this.category,
    this.description,
    this.image,
    this.isOpen = true,
    this.distance,
  });

  /// من خريطة استجابة API (يدعم _id أو id).
  factory Shop.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? json['_id']?.toString();
    return Shop(
      id: id ?? '',
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? '',
      description: json['description'] as String?,
      image: json['image'] as String?,
      isOpen: json['isOpen'] as bool? ?? true,
      distance: json['distance'] is num ? (json['distance'] as num).toDouble() : null,
    );
  }

  final String id;
  final String name;
  final String category;
  final String? description;
  final String? image;
  final bool isOpen;
  final double? distance;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        if (description != null) 'description': description,
        if (image != null) 'image': image,
        'isOpen': isOpen,
        if (distance != null) 'distance': distance,
      };
}
