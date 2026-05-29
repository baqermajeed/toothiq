import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String name;
  final IconData icon;
  final Color iconColor;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    this.iconColor = const Color(0xFF179BAE),
  });
}
