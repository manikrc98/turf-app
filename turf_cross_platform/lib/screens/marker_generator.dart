import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MarkerGenerator {
  /// Generate a custom text marker with a white outline (halo) for loop names
  static Future<BitmapDescriptor> createTextMarker(String text, double pixelRatio) async {
    final double scale = pixelRatio;
    final double fontSize = 14.0 * scale;
    final double strokeWidth = 3.0 * scale;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: text,
      style: TextStyle(
        color: const Color(0xFF2E7D32), // Green
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();

    final double width = textPainter.width + 12.0 * scale;
    final double height = textPainter.height + 12.0 * scale;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final double textX = (width - textPainter.width) / 2;
    final double textY = (height - textPainter.height) / 2;

    // Draw the white outline text first
    final outlinePainter = TextPainter(textDirection: TextDirection.ltr);
    outlinePainter.text = TextSpan(
      text: text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        foreground: Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      ),
    );
    outlinePainter.layout();
    outlinePainter.paint(canvas, Offset(textX, textY));

    // Paint the filled green text on top
    textPainter.paint(canvas, Offset(textX, textY));

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  /// Generate a small white dot marker with a dark blue border
  static Future<BitmapDescriptor> createDotMarker(double pixelRatio) async {
    final double scale = pixelRatio;
    final double size = 16.0 * scale;
    final double center = size / 2;
    final double radius = 5.0 * scale;
    final double strokeWidth = 1.5 * scale;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFF0D47A1) // Deep Blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(Offset(center, center), radius, fillPaint);
    canvas.drawCircle(Offset(center, center), radius, borderPaint);

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  /// Generate a premium rounded card displaying daily streak stats
  static Future<BitmapDescriptor> createCardMarker(
    String name,
    int streak,
    int coveredCount,
    double pixelRatio,
  ) async {
    final double scale = pixelRatio;
    final double paddingX = 14.0 * scale;
    final double paddingY = 10.0 * scale;
    final double lineSpacing = 4.0 * scale;
    final double cornerRadius = 6.0 * scale;
    final double shadowPadding = 3.0 * scale;

    final String daysWord = streak == 1 ? "day" : "days";
    final String loopsWord = coveredCount == 1 ? "loop" : "loops";
    final String line1 = "$streak $daysWord of $name";
    final String line2 = "$coveredCount $loopsWord done today";

    final tp1 = TextPainter(textDirection: TextDirection.ltr);
    tp1.text = TextSpan(
      text: line1,
      style: TextStyle(
        color: const Color(0xFF0D47A1), // Deep Blue
        fontSize: 13.0 * scale,
        fontWeight: FontWeight.bold,
      ),
    );
    tp1.layout();

    final tp2 = TextPainter(textDirection: TextDirection.ltr);
    tp2.text = TextSpan(
      text: line2,
      style: TextStyle(
        color: const Color(0xFF555555), // Slate Gray
        fontSize: 10.5 * scale,
        fontWeight: FontWeight.normal,
      ),
    );
    tp2.layout();

    final double textWidth = max(tp1.width, tp2.width);
    final double cardWidth = textWidth + paddingX * 2;
    final double cardHeight = tp1.height + tp2.height + paddingY * 2 + lineSpacing;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Draw shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.15)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2.0 * scale);
    
    final cardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(shadowPadding, shadowPadding, cardWidth - shadowPadding * 2, cardHeight - shadowPadding * 2),
      Radius.circular(cornerRadius),
    );
    
    canvas.drawRRect(cardRect, shadowPaint);

    // Draw card background
    final cardPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRRect(cardRect, cardPaint);

    // Draw border
    final borderPaint = Paint()
      ..color = const Color(0xFFB0BEC5) // Light gray-blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 * scale;
    canvas.drawRRect(cardRect, borderPaint);

    // Paint Text Lines
    final double centerX = cardWidth / 2;
    final double y1 = paddingY;
    final double y2 = y1 + tp1.height + lineSpacing;

    tp1.paint(canvas, Offset(centerX - tp1.width / 2, y1));
    tp2.paint(canvas, Offset(centerX - tp2.width / 2, y2));

    final picture = recorder.endRecording();
    final img = await picture.toImage(cardWidth.toInt(), cardHeight.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  /// Generate a flat directional arrow user position pointer based on compass heading rotation
  static Future<BitmapDescriptor> createUserPositionMarker(double pixelRatio) async {
    final double scale = pixelRatio;
    final double size = 32.0 * scale;
    final double center = size / 2;
    final double dotRadius = 10.0 * scale;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Pulsing outer ring
    final ringPaint = Paint()
      ..color = const Color(0x402196F3) // Light Blue transparent
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(center, center), size / 2, ringPaint);

    // Core blue dot
    final dotPaint = Paint()
      ..color = const Color(0xFF2196F3) // Blue
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(center, center), dotRadius, dotPaint);

    // Draw arrowhead pointing straight UP (North)
    final arrowPath = Path();
    final double arrowHeight = 6.0 * scale;
    final double arrowWidth = 8.0 * scale;
    
    // Top tip
    arrowPath.moveTo(center, center - dotRadius - arrowHeight);
    // Bottom-left corner
    arrowPath.lineTo(center - (arrowWidth / 2), center - dotRadius + 1.0 * scale);
    // Bottom-right corner
    arrowPath.lineTo(center + (arrowWidth / 2), center - dotRadius + 1.0 * scale);
    arrowPath.close();
    
    canvas.drawPath(arrowPath, dotPaint);

    // Outline paints
    final outlinePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * scale;
    canvas.drawCircle(Offset(center, center), dotRadius, outlinePaint);

    final arrowOutlinePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 * scale;
    canvas.drawPath(arrowPath, arrowOutlinePaint);

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }
}
