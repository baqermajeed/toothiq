import 'package:get/get.dart';

/// تبويب الشريط السفلي في الـ shell الرئيسي.
const int kTabHome = 0;
const int kTabCategories = 1;
const int kTabOrders = 2;
const int kTabProfile = 3;

/// Controller للـ MainShell: يحتفظ بفهرس التبويب الحالي.
class MainShellController extends GetxController {
  final currentIndex = 0.obs;

  void setTab(int index) {
    currentIndex.value = index;
  }
}
