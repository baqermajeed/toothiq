import 'package:get/get.dart';

import '../controller/saved_addresses_controller.dart';

class SavedAddressesBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<SavedAddressesController>()) {
      Get.put(SavedAddressesController(), permanent: true);
    }
  }
}
