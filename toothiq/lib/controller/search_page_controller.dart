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

  static const List<String> _defaultHistory = [
    'سجل البحث',
    'سجل البحث',
    'سجل البحث',
    'سجل البحث',
  ];

  @override
  void onInit() {
    super.onInit();
    _loadHistory();
    _loadRecentStores();
  }

  void _loadHistory() {
    final saved = _prefs.getStringList(StorageKeys.searchHistory);
    if (saved != null && saved.isNotEmpty) {
      searchHistory.assignAll(saved);
      return;
    }
    searchHistory.assignAll(_defaultHistory);
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
    searchHistory.remove(query);
    searchHistory.insert(0, query);
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
