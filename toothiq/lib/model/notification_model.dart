import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

enum NotificationIconType {
  clock,
  update,
  order,
  product,
  store,
}

enum NotificationDayGroup {
  today,
  yesterday,
  older,
}

class AppNotificationModel {
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final String? type;
  final String? orderId;
  final String? productId;
  final String? shopId;
  final String? storeId;
  final bool isRead;

  const AppNotificationModel({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    this.type,
    this.orderId,
    this.productId,
    this.shopId,
    this.storeId,
    this.isRead = false,
  });

  NotificationDayGroup get group => groupForDate(createdAt);

  String get timeLabel => formatTimeLabel(createdAt);

  NotificationIconType get iconType {
    if (type == 'app_update') return NotificationIconType.update;
    if (type == 'product' || (productId != null && productId!.isNotEmpty)) {
      return NotificationIconType.product;
    }
    if (type == 'store' || (storeId != null && storeId!.isNotEmpty)) {
      return NotificationIconType.store;
    }
    if (isOrderNotification) return NotificationIconType.order;
    return NotificationIconType.clock;
  }

  IconData get iconData => switch (iconType) {
        NotificationIconType.clock => Icons.notifications_outlined,
        NotificationIconType.update => Icons.system_update_rounded,
        NotificationIconType.order => Icons.local_shipping_outlined,
        NotificationIconType.product => Icons.shopping_bag_outlined,
        NotificationIconType.store => Icons.storefront_outlined,
      };

  String get groupTitle => switch (group) {
        NotificationDayGroup.today => 'اليوم',
        NotificationDayGroup.yesterday => 'أمس',
        NotificationDayGroup.older => 'أقدم',
      };

  bool get isOrderNotification {
    if (orderId == null || orderId!.isEmpty) return false;
    if (type == null || type!.isEmpty) return true;
    return type!.startsWith('order_') || type == 'new_order';
  }

  bool get isProductNotification =>
      type == 'product' && productId != null && productId!.isNotEmpty;

  bool get isStoreNotification =>
      type == 'store' &&
      ((storeId != null && storeId!.isNotEmpty) ||
          (shopId != null && shopId!.isNotEmpty));

  bool get canOpenTarget =>
      isOrderNotification || isProductNotification || isStoreNotification;

  AppNotificationModel copyWith({bool? isRead}) {
    return AppNotificationModel(
      id: id,
      title: title,
      description: description,
      createdAt: createdAt,
      type: type,
      orderId: orderId,
      productId: productId,
      shopId: shopId,
      storeId: storeId,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'createdAt': createdAt.toIso8601String(),
        if (type != null) 'type': type,
        if (orderId != null) 'orderId': orderId,
        if (productId != null) 'productId': productId,
        if (shopId != null) 'shopId': shopId,
        if (storeId != null) 'storeId': storeId,
        'isRead': isRead,
      };

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    final nested = json['data'];
    final data = nested is Map<String, dynamic> ? nested : const <String, dynamic>{};
    return AppNotificationModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'إشعار',
      description: json['description']?.toString() ??
          json['body']?.toString() ??
          '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      type: json['type']?.toString() ?? data['type']?.toString(),
      orderId: json['orderId']?.toString() ?? data['orderId']?.toString(),
      productId: json['productId']?.toString() ?? data['productId']?.toString(),
      shopId: json['shopId']?.toString() ?? data['shopId']?.toString(),
      storeId: json['storeId']?.toString() ?? data['storeId']?.toString(),
      isRead: json['isRead'] == true,
    );
  }

  factory AppNotificationModel.fromApiJson(Map<String, dynamic> json) {
    return AppNotificationModel.fromJson(json);
  }

  factory AppNotificationModel.fromRemoteMessage(RemoteMessage message) {
    final data = message.data;
    final type = data['type']?.toString();
    final orderId = data['orderId']?.toString();
    final productId = data['productId']?.toString();
    final shopId = data['shopId']?.toString();
    final storeId = data['storeId']?.toString();
    final sentAt = message.sentTime ?? DateTime.now();
    final id = message.messageId?.trim().isNotEmpty == true
        ? message.messageId!
        : '${type ?? 'msg'}_${orderId ?? productId ?? storeId ?? ''}_${sentAt.millisecondsSinceEpoch}';

    return AppNotificationModel(
      id: id,
      title: message.notification?.title?.trim().isNotEmpty == true
          ? message.notification!.title!
          : _defaultTitleForType(type),
      description: message.notification?.body?.trim().isNotEmpty == true
          ? message.notification!.body!
          : data['body']?.toString() ?? '',
      createdAt: sentAt,
      type: type,
      orderId: orderId,
      productId: productId,
      shopId: shopId,
      storeId: storeId,
    );
  }

  static String _defaultTitleForType(String? type) {
    switch (type) {
      case 'order_accepted':
        return 'تم قبول طلبك';
      case 'order_preparing':
        return 'جارٍ تحضير طلبك';
      case 'order_on_the_way':
        return 'طلبك في الطريق';
      case 'order_delivered':
        return 'تم توصيل طلبك';
      case 'order_canceled':
        return 'تم إلغاء الطلب';
      case 'order_postponed':
        return 'تم تأجيل الطلب';
      case 'new_order':
        return 'طلب جديد';
      case 'product':
        return 'منتج جديد';
      case 'store':
        return 'متجر';
      default:
        return 'إشعار';
    }
  }

  static NotificationDayGroup groupForDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final created = DateTime(date.year, date.month, date.day);
    final diffDays = today.difference(created).inDays;
    if (diffDays <= 0) return NotificationDayGroup.today;
    if (diffDays == 1) return NotificationDayGroup.yesterday;
    return NotificationDayGroup.older;
  }

  static String formatTimeLabel(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inHours < 1) return 'منذ ${diff.inMinutes} دقيقة';
    if (groupForDate(date) == NotificationDayGroup.today) {
      return 'منذ ${diff.inHours} ساعة';
    }
    if (groupForDate(date) == NotificationDayGroup.yesterday) {
      return 'أمس';
    }
    return '${date.year}-${date.month}-${date.day}';
  }
}
