import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_svg/svg.dart' as vg;
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'map_debug_logger.dart';

/// Helper لإنشاء أيقونات مخصصة للخريطة من SVG أو أيقونات Flutter.
class MapMarkerHelper {
  /// تحويل SVG إلى BitmapDescriptor للاستخدام في Google Maps.
  /// عند [addPinPoint]=true تُضاف نقطة ربط مرئية أسفل الأيقونة بحيث يلمس الطرف الموقع الفعلي
  /// (مثل الدبوس الافتراضي) — استخدم مع anchor: Offset(0.5, 1.0).
  static Future<BitmapDescriptor> getBitmapDescriptorFromSvg(
    String assetPath, {
    double width = 48,
    double height = 48,
    Color? color,
    bool addPinPoint = false,
  }) async {
    try {
      MapDebugLogger.iconFromSvgStart(assetPath);
      final String svgString = await rootBundle.loadString(assetPath);
      MapDebugLogger.svgStringLoaded();
      final pictureInfo = await vg.vg.loadPicture(
        SvgStringLoader(svgString),
        null,
      );

      final int iconW = width.toInt();
      int iconH = height.toInt();
      const int pinPointHeight = 12;

      if (addPinPoint) {
        iconH += pinPointHeight;
      }

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // رسم SVG
      canvas.save();
      canvas.scale(width / 24, height / 24);
      canvas.drawPicture(pictureInfo.picture);
      canvas.restore();
      pictureInfo.picture.dispose();
      MapDebugLogger.svgPictureDrawn();

      if (addPinPoint) {
        final pointColor = color ?? const Color(0xFF1C274C);
        final circlePaint = Paint()
          ..color = pointColor
          ..style = PaintingStyle.fill;
        final cx = width / 2;
        final cy = (iconH - 6).toDouble();
        canvas.drawCircle(Offset(cx, cy), 5, circlePaint);
      }

      final picture = recorder.endRecording();
      MapDebugLogger.pictureToImageStart();
      final image = await picture.toImage(iconW, iconH);
      MapDebugLogger.pictureToImageEnd();

      MapDebugLogger.toByteDataStart();
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        throw Exception('Failed to convert image to ByteData');
      }

      MapDebugLogger.toByteDataEnd();
      return BitmapDescriptor.bytes(byteData.buffer.asUint8List());
    } catch (e, st) {
      MapDebugLogger.error('getBitmapDescriptorFromSvg', e, st);
      debugPrint('Error loading SVG marker: $e');
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
    }
  }

  /// إنشاء أيقونة مخصصة من Icon Widget.
  static Future<BitmapDescriptor> getBitmapDescriptorFromIcon(
    IconData icon, {
    Color color = Colors.orange,
    double size = 48,
    Color backgroundColor = Colors.white,
    double padding = 8,
  }) async {
    try {
      MapDebugLogger.iconFromIconStart();
      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      final totalSize = size + (padding * 2);

      // رسم خلفية دائرية مع حدود
      final bgPaint = Paint()
        ..color = backgroundColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(totalSize / 2, totalSize / 2),
        totalSize / 2,
        bgPaint,
      );

      // رسم حدود الدائرة
      final borderPaint = Paint()
        ..color = color.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(
        Offset(totalSize / 2, totalSize / 2),
        totalSize / 2 - 1,
        borderPaint,
      );

      // رسم الأيقونة
      final textPainter = TextPainter(textDirection: TextDirection.ltr);
      textPainter.text = TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: size * 0.8,
          fontFamily: icon.fontFamily,
          color: color,
        ),
      );
      textPainter.layout();
      
      // توسيط الأيقونة
      final iconOffset = Offset(
        (totalSize - textPainter.width) / 2,
        (totalSize - textPainter.height) / 2,
      );
      textPainter.paint(canvas, iconOffset);

      final picture = pictureRecorder.endRecording();
      MapDebugLogger.pictureToImageStart();
      final image = await picture.toImage(
        totalSize.toInt(),
        totalSize.toInt(),
      );
      MapDebugLogger.pictureToImageEnd();

      MapDebugLogger.toByteDataStart();
      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        throw Exception('Failed to convert icon to ByteData');
      }

      MapDebugLogger.toByteDataEnd();
      MapDebugLogger.iconFromIconEnd();
      return BitmapDescriptor.bytes(byteData.buffer.asUint8List());
    } catch (e, st) {
      MapDebugLogger.error('getBitmapDescriptorFromIcon', e, st);
      debugPrint('Error creating icon marker: $e');
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
    }
  }
}
