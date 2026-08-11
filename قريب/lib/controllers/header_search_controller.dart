import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// تحكم وضع البحث في الهيدر — فتح/إغلاق مربع البحث وتنفيذ الطلب.
class HeaderSearchController extends GetxController {
  final RxBool isSearchMode = false.obs;
  final TextEditingController textController = TextEditingController();
  final FocusNode focusNode = FocusNode();

  void openSearch() {
    isSearchMode.value = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNode.requestFocus();
    });
  }

  void closeSearch() {
    textController.clear();
    focusNode.unfocus();
    isSearchMode.value = false;
  }

  void submitSearch() {
    final query = textController.text.trim();
    if (query.isEmpty) return;
    closeSearch();
    Get.toNamed('/search', arguments: query);
  }

  @override
  void onClose() {
    textController.dispose();
    focusNode.dispose();
    super.onClose();
  }
}
