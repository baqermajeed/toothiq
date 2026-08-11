import 'package:get/get.dart';

import '../controller/section_detail_controller.dart';
import '../model/category_model.dart';

class SectionDetailBinding extends Bindings {
  final CategoryModel category;

  SectionDetailBinding({required this.category});

  @override
  void dependencies() {
    Get.lazyPut<SectionDetailController>(
      () => SectionDetailController(category: category),
    );
  }
}
