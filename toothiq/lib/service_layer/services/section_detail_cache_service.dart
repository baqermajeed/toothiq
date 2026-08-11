import '../../model/section_detail_cache_entry.dart';

class SectionDetailCacheService {
  final _entries = <String, SectionDetailCacheEntry>{};

  SectionDetailCacheEntry? get(String categoryId) {
    if (categoryId.trim().isEmpty) return null;
    return _entries[categoryId];
  }

  void put(String categoryId, SectionDetailCacheEntry entry) {
    if (categoryId.trim().isEmpty) return;
    _entries[categoryId] = entry;
  }

  void remove(String categoryId) {
    _entries.remove(categoryId);
  }

  void clear() => _entries.clear();
}
