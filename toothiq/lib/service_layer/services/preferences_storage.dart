import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// تفضيلات التطبيق غير الحساسة (مثل قريب: SharedPreferences للتفضيلات + Secure للتوكن).
class PreferencesStorage {
  PreferencesStorage(this._prefs);

  final SharedPreferences _prefs;
  static PreferencesStorage? _instance;

  static Future<PreferencesStorage> init() async {
    final prefs = await SharedPreferences.getInstance();
    _instance = PreferencesStorage(prefs);
    return _instance!;
  }

  static PreferencesStorage get instance {
    final storage = _instance;
    if (storage == null) {
      throw StateError('PreferencesStorage.init() must be called before use.');
    }
    return storage;
  }

  bool? getBool(String key) => _prefs.getBool(key);

  Future<bool> setBool(String key, bool value) => _prefs.setBool(key, value);

  String? getString(String key) => _prefs.getString(key);

  Future<bool> setString(String key, String value) =>
      _prefs.setString(key, value);

  List<String>? getStringList(String key) => _prefs.getStringList(key);

  Future<bool> setStringList(String key, List<String> value) =>
      _prefs.setStringList(key, value);

  Future<bool> setJsonList(String key, List<Map<String, dynamic>> value) {
    return setString(key, jsonEncode(value));
  }

  List<Map<String, dynamic>>? getJsonList(String key) {
    final raw = getString(key);
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! List) return null;
    return decoded
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(growable: false);
  }

  Future<bool> remove(String key) => _prefs.remove(key);
}
