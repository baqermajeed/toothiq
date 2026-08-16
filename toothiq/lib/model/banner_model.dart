import '../../core/utils/image_url.dart';
import 'product_model.dart';
import 'store_model.dart';

enum BannerActionType { none, shop, product, externalUrl }

class BannerModel {
  final String id;
  final String imageUrl;
  final String? title;
  final BannerActionType actionType;
  final String? shopId;
  final String? productId;
  final StoreModel? shop;
  final ProductModel? product;
  final String? externalUrl;

  const BannerModel({
    required this.id,
    required this.imageUrl,
    this.title,
    this.actionType = BannerActionType.none,
    this.shopId,
    this.productId,
    this.shop,
    this.product,
    this.externalUrl,
  });

  bool get canOpen =>
      (actionType == BannerActionType.shop && _resolvedShopId.isNotEmpty) ||
      (actionType == BannerActionType.product && _resolvedProductId.isNotEmpty);

  String get _resolvedShopId =>
      (shopId ?? shop?.id ?? '').trim();

  String get _resolvedProductId =>
      (productId ?? product?.id ?? '').trim();

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    final type = _parseAction(json['actionType']?.toString());
    final shopJson = json['shop'];
    final productJson = json['product'];
    final shop = shopJson is Map<String, dynamic>
        ? StoreModel.fromJson(shopJson)
        : null;
    final product = productJson is Map<String, dynamic>
        ? ProductModel.fromJson(productJson)
        : null;
    final shopId = json['shopId']?.toString() ?? shop?.id;
    final productId = json['productId']?.toString() ?? product?.id;

    return BannerModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      imageUrl: ImageUrl.resolve(
        json['image']?.toString() ?? json['imageUrl']?.toString(),
        fallback: ImageUrl.bannerPlaceholder,
      ),
      title: json['title']?.toString(),
      actionType: type,
      shopId: (shopId != null && shopId.isNotEmpty) ? shopId : null,
      productId: (productId != null && productId.isNotEmpty) ? productId : null,
      shop: shop,
      product: product,
      externalUrl: json['externalUrl']?.toString() ?? json['link']?.toString(),
    );
  }

  static BannerActionType _parseAction(String? raw) {
    switch (raw) {
      case 'shop':
        return BannerActionType.shop;
      case 'product':
        return BannerActionType.product;
      case 'external_url':
        return BannerActionType.externalUrl;
      default:
        return BannerActionType.none;
    }
  }
}
