class StoreReviewModel {
  final String id;
  final String userName;
  final String? avatarAsset;
  final int rating;
  final String timeAgo;
  final String text;

  const StoreReviewModel({
    required this.id,
    required this.userName,
    required this.rating,
    required this.timeAgo,
    required this.text,
    this.avatarAsset,
  });

  factory StoreReviewModel.fromJson(Map<String, dynamic> json) {
    final user = json['userId'] is Map<String, dynamic>
        ? json['userId'] as Map<String, dynamic>
        : <String, dynamic>{};
    final createdAt = DateTime.tryParse(json['createdAt']?.toString() ?? '');

    return StoreReviewModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      userName: user['name']?.toString() ?? 'مستخدم',
      rating: (json['rating'] as num?)?.toInt() ?? 5,
      timeAgo: _timeAgo(createdAt),
      text: json['comment']?.toString() ??
          json['text']?.toString() ??
          'لا يوجد تعليق',
      avatarAsset: null,
    );
  }

  static String _timeAgo(DateTime? date) {
    if (date == null) return 'الآن';
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return 'منذ ${diff.inDays} يوم';
    if (diff.inHours > 0) return 'منذ ${diff.inHours} ساعة';
    if (diff.inMinutes > 0) return 'منذ ${diff.inMinutes} دقيقة';
    return 'الآن';
  }
}
