import 'package:flutter/material.dart';

enum NotificationIconType {
  clock,
  update,
}

enum NotificationDayGroup {
  today,
  yesterday,
}

class AppNotificationModel {
  final String id;
  final String title;
  final String description;
  final String timeLabel;
  final NotificationDayGroup group;
  final NotificationIconType iconType;

  const AppNotificationModel({
    required this.id,
    required this.title,
    required this.description,
    required this.timeLabel,
    required this.group,
    this.iconType = NotificationIconType.clock,
  });

  IconData get iconData => switch (iconType) {
        NotificationIconType.clock => Icons.access_time_rounded,
        NotificationIconType.update => Icons.eco_outlined,
      };

  String get groupTitle => switch (group) {
        NotificationDayGroup.today => 'اليوم',
        NotificationDayGroup.yesterday => 'أمس',
      };
}
