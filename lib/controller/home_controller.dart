import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../model/product_model.dart';

class HomeController extends GetxController {
  final searchController = TextEditingController();
  final bannerPageController = PageController();
  final bannerIndex = 0.obs;
  final selectedCategoryIndex = 0.obs;
  final hasNotification = true.obs;

  final categories = <String>[
    'الكل',
    'حشوات',
    'تقويم',
    'تعقيم',
    'أدوات',
  ].obs;

  final products = <ProductModel>[
    const ProductModel(
      id: '1',
      name: 'فرشاة أسنان خشبية',
      storeName: 'أسم المتجر',
      description: 'وصف وصف وصف وصف وصف وصف وصف وصف',
      fullDescription:
          'فرشاة أسنان خشبية صديقة للبيئة بمقبض خشبي طبيعي وشعيرات ناعمة. مناسبة للاستخدام اليومي في العيادات والمنازل، خفيفة الوزن وسهلة التنظيف.',
      price: 26000,
      imageAsset: 'assets/images/products/product_1.png',
      galleryAssets: [
        'assets/images/products/product_1.png',
        'assets/images/products/product_2.png',
        'assets/images/products/product_1.png',
        'assets/images/products/product_2.png',
      ],
      expirationDate: '1 / 5 / 2026',
      isFavorite: true,
    ),
    const ProductModel(
      id: '2',
      name: 'أسم المنتج',
      storeName: 'أسم المتجر',
      description: 'وصف وصف وصف وصف وصف وصف وصف وصف',
      price: 26000,
      imageAsset: 'assets/images/products/product_2.png',
      isFavorite: true,
    ),
    const ProductModel(
      id: '3',
      name: 'أسم المنتج',
      storeName: 'أسم المتجر',
      description: 'وصف وصف وصف وصف وصف وصف وصف وصف',
      price: 26000,
      imageAsset: 'assets/images/products/product_1.png',
      isFavorite: true,
    ),
    const ProductModel(
      id: '4',
      name: 'أسم المنتج',
      storeName: 'أسم المتجر',
      description: 'وصف وصف وصف وصف وصف وصف وصف وصف',
      price: 26000,
      imageAsset: 'assets/images/products/product_2.png',
      isFavorite: true,
    ),
    const ProductModel(
      id: '5',
      name: 'أسم المنتج',
      storeName: 'أسم المتجر',
      description: 'وصف وصف وصف وصف وصف وصف وصف وصف',
      price: 26000,
      imageAsset: 'assets/images/products/product_1.png',
      isFavorite: true,
    ),
    const ProductModel(
      id: '6',
      name: 'أسم المنتج',
      storeName: 'أسم المتجر',
      description: 'وصف وصف وصف وصف وصف وصف وصف وصف',
      price: 26000,
      imageAsset: 'assets/images/products/product_2.png',
      isFavorite: true,
    ),
  ].obs;

  static const List<String> bannerAssets = [
    'assets/images/banners/promo_banner.png',
    'assets/images/banners/promo_banner.png',
    'assets/images/banners/promo_banner.png',
    'assets/images/banners/promo_banner.png',
  ];

  @override
  void onClose() {
    searchController.dispose();
    bannerPageController.dispose();
    super.onClose();
  }

  void selectCategory(int index) {
    selectedCategoryIndex.value = index;
  }

  void toggleFavorite(String productId) {
    final index = products.indexWhere((p) => p.id == productId);
    if (index == -1) return;
    products[index] = products[index].copyWith(
      isFavorite: !products[index].isFavorite,
    );
    products.refresh();
  }

  void onBannerChanged(int index) {
    bannerIndex.value = index;
  }
}
