import 'preferences_storage.dart';

/// يحفظ كميات المنتجات محلياً لأن السيرفر حالياً لا يُرجع حقل الكمية.
class ProductStockCache {
  ProductStockCache(this._prefs);

  static const _key = 'shop_product_stock';

  final PreferencesStorage _prefs;
  Map<String, int> _memory = {};
  bool _loaded = false;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final json = _prefs.getJson(_key);
    if (json != null) {
      _memory = {
        for (final entry in json.entries)
          entry.key: _parseInt(entry.value) ?? 0,
      }..removeWhere((_, value) => value <= 0);
    }
    _loaded = true;
  }

  int? get(String productId) {
    final value = _memory[productId];
    if (value == null || value <= 0) return null;
    return value;
  }

  Future<void> save(String productId, int stock) async {
    await ensureLoaded();
    if (stock > 0) {
      _memory[productId] = stock;
    } else {
      _memory.remove(productId);
    }
    await _persist();
  }

  Future<void> remove(String productId) async {
    await ensureLoaded();
    _memory.remove(productId);
    await _persist();
  }

  Future<void> _persist() async {
    await _prefs.setJson(
      _key,
      _memory.map((key, value) => MapEntry(key, value)),
    );
  }

  int? _parseInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }
}
