import 'package:get/get.dart';

import '../controller/notifications_controller.dart';

class NotificationsBinding extends Bindings {
  @override
  void dependencies() {
    // fenix: recreate after route dispose so reopen / leave races don't crash.
    Get.lazyPut<NotificationsController>(
      () => NotificationsController(),
      fenix: true,
    );
  }
}
