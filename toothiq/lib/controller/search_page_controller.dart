import 'package:get/get.dart';

import '../model/search_filter_model.dart';
import '../model/store_model.dart';
import '../service_layer/services/preferences_storage.dart';
import '../service_layer/services/shop_service.dart';
import '../utils/storage_keys.dart';
import '../view/search/search_filter_page.dart';

class SearchPageController extends GetxController {
  final ShopService _shopService = Get.find<ShopService>();

  final searchHistory = <String>[].obs;
  final recentStores = <StoreModel>[].obs;
  final filter = const SearchFilterModel().obs;

  final _prefs = PreferencesStorage.instance;

  @override
  void onInit() {
    super.onInit();
    _loadHistory();
    _loadRecentStores();
  }

  void _loadHistory() {
    final saved = _prefs.getStringList(StorageKeys.searchHistory);
    final cleaned = _sanitizeHistory(saved ?? const []);
    searchHistory.assignAll(cleaned);
    if (saved != null && cleaned.length != saved.length) {
      _saveHistory();
    }
  }

  Future<void> _saveHistory() async {
    await _prefs.setStringList(StorageKeys.searchHistory, searchHistory.toList());
  }

  Future<void> _loadRecentStores() async {
    try {
      final stores = await _shopService.fetchShops(limit: 5);
      recentStores.assignAll(stores);
    } catch (_) {
      recentStores.clear();
    }
  }

  void addToHistory(String query) {
    final normalized = query.trim();
    if (normalized.isEmpty || normalized == 'سجل البحث') return;
    searchHistory.remove(normalized);
    searchHistory.insert(0, normalized);
    if (searchHistory.length > 10) {
      searchHistory.removeRange(10, searchHistory.length);
    }
    _saveHistory();
  }

  void removeHistoryItem(String item) {
    searchHistory.remove(item);
    _saveHistory();
  }

  void clearHistory() {
    searchHistory.clear();
    _saveHistory();
  }

  List<String> _sanitizeHistory(List<String> values) {
    return values
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty && item != 'سجل البحث')
        .toSet()
        .toList(growable: false);
  }

  Future<void> openFilter(String query) async {
    final result = await SearchFilterPage.open(
      initialFilter: filter.value,
      searchQuery: query,
      navigateToResultsOnApply: true,
    );
    if (result == null) return;
    filter.value = result;
  }
}
