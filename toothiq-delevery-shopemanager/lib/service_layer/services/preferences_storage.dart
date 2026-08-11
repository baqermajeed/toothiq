import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

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

  Future<bool> setJson(String key, Map<String, dynamic> value) {
    return setString(key, jsonEncode(value));
  }

  Map<String, dynamic>? getJson(String key) {
    final raw = getString(key);
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    return Map<String, dynamic>.from(decoded);
  }

  Future<bool> remove(String key) => _prefs.remove(key);
}
