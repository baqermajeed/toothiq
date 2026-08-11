import 'package:flutter/material.dart';

enum SettingsItemKind {
  navigation,
  toggle,
}

class SettingsMenuItem {
  final String id;
  final String title;
  final IconData icon;
  final SettingsItemKind kind;
  final Color? titleColor;
  final Color? iconColor;

  const SettingsMenuItem({
    required this.id,
    required this.title,
    required this.icon,
    this.kind = SettingsItemKind.navigation,
    this.titleColor,
    this.iconColor,
  });
}

class SettingsSection {
  final String title;
  final List<SettingsMenuItem> items;

  const SettingsSection({
    required this.title,
    required this.items,
  });
}
