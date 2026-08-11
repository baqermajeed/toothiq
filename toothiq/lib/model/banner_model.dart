import '../../core/utils/image_url.dart';

class BannerModel {
  final String id;
  final String imageUrl;
  final String? link;

  const BannerModel({
    required this.id,
    required this.imageUrl,
    this.link,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      imageUrl: ImageUrl.resolve(
        json['image']?.toString() ?? json['imageUrl']?.toString(),
        fallback: ImageUrl.bannerPlaceholder,
      ),
      link: json['link']?.toString(),
    );
  }
}
