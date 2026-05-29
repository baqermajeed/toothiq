import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../model/store_model.dart';

class StoresController extends GetxController {
  final searchController = TextEditingController();

  final stores = <StoreModel>[
    const StoreModel(
      id: '1',
      name: 'أسم المتجر',
      description: 'وصف وصف وصف وصف وصف وصف وصف وصف وصف وصف',
    ),
    const StoreModel(
      id: '2',
      name: 'أسم المتجر',
      description: 'وصف وصف وصف وصف وصف وصف وصف وصف وصف وصف',
      rating: 4.5,
    ),
    const StoreModel(
      id: '3',
      name: 'أسم المتجر',
      description: 'وصف وصف وصف وصف وصف وصف وصف وصف وصف وصف',
    ),
    const StoreModel(
      id: '4',
      name: 'أسم المتجر',
      description: 'وصف وصف وصف وصف وصف وصف وصف وصف وصف وصف',
    ),
  ].obs;

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  void onViewStore(String storeId) {
    // TODO: التنقل لصفحة تفاصيل المتجر عند جاهزية التصميم والـ API
  }
}
