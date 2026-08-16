class DriverReviewModel {
  final String id;
  final int rating;
  final String comment;
  final DateTime? createdAt;

  const DriverReviewModel({
    required this.id,
    required this.rating,
    this.comment = '',
    this.createdAt,
  });

  factory DriverReviewModel.fromJson(Map<String, dynamic> json) {
    return DriverReviewModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}
