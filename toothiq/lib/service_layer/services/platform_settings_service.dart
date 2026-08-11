import 'package:get/get.dart';

import '../../core/api/api_client.dart';
import '../../model/app_contact_model.dart';

class PlatformSettingsService extends GetxService {
  final ApiClient _api;

  PlatformSettingsService(this._api);

  final contact = AppContactModel.empty.obs;
  final isLoading = false.obs;

  int get globalDeliveryFee => contact.value.globalDeliveryFee;
  bool get deliveryEnabled => contact.value.deliveryEnabled;

  String get formattedDeliveryFee => contact.value.formatDeliveryFeeLabel();

  Future<void> load({bool forceRefresh = false}) async {
    if (isLoading.value) return;
    if (!forceRefresh && contact.value != AppContactModel.empty) return;

    isLoading.value = true;
    try {
      var settings = await _api.getAppContact();

      if (settings.globalDeliveryFee <= 0) {
        final adminSettings = await _api.getAdminSettings();
        if (adminSettings != null) {
          final fallbackFee = AppContactModel.readDeliveryFee(adminSettings);
          settings = settings.copyWith(
            globalDeliveryFee: fallbackFee,
            deliveryEnabled:
                _readBool(adminSettings['deliveryEnabled']) ??
                settings.deliveryEnabled,
            deliveryPauseReason:
                adminSettings['deliveryPauseReason']?.toString().trim().isNotEmpty ==
                    true
                ? adminSettings['deliveryPauseReason'].toString().trim()
                : settings.deliveryPauseReason,
          );
        }
      }

      contact.value = settings;
    } catch (_) {
      contact.value = AppContactModel.empty;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refresh() => load(forceRefresh: true);

  bool? _readBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) {
      final v = value.trim().toLowerCase();
      if (v == 'true' || v == '1') return true;
      if (v == 'false' || v == '0') return false;
    }
    return null;
  }
}
