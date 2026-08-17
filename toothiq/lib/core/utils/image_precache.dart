import 'dart:async';

import 'package:flutter/material.dart';

import 'image_url.dart';

abstract final class ImagePrecache {
  static const Duration _timeout = Duration(milliseconds: 1600);

  static Future<void> urls(
    BuildContext? context,
    Iterable<String?> sources,
  ) async {
    if (context == null || !context.mounted) return;

    final seen = <String>{};
    final futures = <Future<void>>[];

    for (final source in sources) {
      if (source == null || source.trim().isEmpty) continue;
      final resolved = ImageUrl.resolve(source);
      if (!seen.add(resolved)) continue;

      final ImageProvider provider = ImageUrl.isNetwork(resolved)
          ? NetworkImage(resolved)
          : AssetImage(resolved);

      futures.add(() async {
        try {
          await precacheImage(provider, context);
        } catch (_) {}
      }());
    }

    if (futures.isEmpty) return;

    try {
      await Future.wait(futures).timeout(_timeout);
    } on TimeoutException {
      // الصور المتبقية تكمل التحميل داخل AppImage مع الـ shimmer.
    }
  }
}
