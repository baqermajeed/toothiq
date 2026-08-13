import 'package:get/get.dart';

import '../controller/section_detail_controller.dart';
import '../model/category_model.dart';

class SectionDetailBinding extends Bindings {
  final CategoryModel category;
  final String? shopId;
  final String? shopName;

  SectionDetailBinding({
    required this.category,
    this.shopId,
    this.shopName,
  });

  @override
  void dependencies() {
    if (Get.isRegistered<SectionDetailController>()) {
      Get.delete<SectionDetailController>(force: true);
    }
    Get.put(
      SectionDetailController(
        category: category,
        shopId: shopId,
        shopName: shopName,
      ),
    );
  }
}
