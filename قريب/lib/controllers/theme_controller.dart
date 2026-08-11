import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kThemeKey = 'is_dark_mode';

/// تحكم بثيم التطبيق (فاتح/داكن) مع تخزين التفضيل محلياً.
class ThemeController extends GetxController {
  ThemeController() : _prefs = null {
    _themeMode = ThemeMode.light.obs;
  }

  SharedPreferences? _prefs;
  late final Rx<ThemeMode> _themeMode;

  ThemeMode get themeMode => _themeMode.value;
  bool get isDarkMode => _themeMode.value == ThemeMode.dark;

  @override
  void onInit() {
    super.onInit();
    _loadAndApply();
  }

  Future<void> _loadAndApply() async {
    _prefs = await SharedPreferences.getInstance();
    final isDark = _prefs?.getBool(_kThemeKey) ?? false;
    _themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggleDarkMode() async {
    final next = _themeMode.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    _themeMode.value = next;
    await _prefs?.setBool(_kThemeKey, next == ThemeMode.dark);
  }
}
