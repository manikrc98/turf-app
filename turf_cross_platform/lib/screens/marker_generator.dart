import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MarkerGenerator {
  /// Generate a custom text marker for loop names in Space Grotesk 700 uppercase
  static Future<BitmapDescriptor> createTextMarker(String text, double pixelRatio) async {
    final double scale = pixelRatio;
    final double fontSize = 13.0 * scale;
    final double strokeWidth = 2.0 * scale;

    final String upperText = text.toUpperCase();

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: upperText,
      style: GoogleFonts.spaceGrotesk(
        color: const Color(0xFFB8FF00), // Lime green #B8FF00
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        letterSpacing: fontSize * 0.04,
      ),
    );
    textPainter.layout();

    final double width = textPainter.width + 12.0 * scale;
    final double height = textPainter.height + 12.0 * scale;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final double textX = (width - textPainter.width) / 2;
    final double textY = (height - textPainter.height) / 2;

    // Draw the dark outline (halo) for high readability over dark tiles
    final outlinePainter = TextPainter(textDirection: TextDirection.ltr);
    outlinePainter.text = TextSpan(
      text: upperText,
      style: GoogleFonts.spaceGrotesk(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        letterSpacing: fontSize * 0.04,
        foreground: Paint()
          ..color = const Color(0xFF0A0A0A) // Background color outline
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.square
          ..strokeJoin = StrokeJoin.miter,
      ),
    );
    outlinePainter.layout();
    outlinePainter.paint(canvas, Offset(textX, textY));

    // Paint the filled text
    textPainter.paint(canvas, Offset(textX, textY));

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  /// Generate a desaturated grey dot marker with a dark border (no blue)
  static Future<BitmapDescriptor> createDotMarker(double pixelRatio) async {
    final double scale = pixelRatio;
    final double size = 16.0 * scale;
    final double center = size / 2;
    final double radius = 4.5 * scale;
    final double strokeWidth = 1.5 * scale;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final fillPaint = Paint()
      ..color = const Color(0xFFEBEBEB) // Muted light grey dot
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFF4A4A4A) // Desaturated Ghost border
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(Offset(center, center), radius, fillPaint);
    canvas.drawCircle(Offset(center, center), radius, borderPaint);

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  /// Generate a flat dark card showing loop state stats (0 border-radius, #141414 surface)
  static Future<BitmapDescriptor> createCardMarker(
    String name,
    int streak,
    int coveredCount,
    double pixelRatio,
    bool isActive,
    String ownerName,
    bool isMyClaim,
  ) async {
    final double scale = pixelRatio;
    final double paddingX = 14.0 * scale;
    final double paddingY = 10.0 * scale;
    final double lineSpacing = 4.0 * scale;

    // Determine semantic status, colors, and layout variables
    final String statusText;
    final Color semanticColor;

    if (!isActive || ownerName.isEmpty) {
      statusText = "GHOST";
      semanticColor = const Color(0xFF4A4A4A); // Ghost grey
    } else if (isMyClaim) {
      statusText = "HELD · ${streak}D_STREAK";
      semanticColor = const Color(0xFFB8FF00); // Lime green #B8FF00
    } else {
      statusText = "CONTESTED · ${streak}D_STREAK";
      semanticColor = const Color(0xFFFF6B00); // Contested orange
    }

    final String zoneNameUpper = name.toUpperCase();
    
    // Format owner details and date/time info
    final String ownerClean = ownerName.isEmpty ? "UNCLAIMED" : ownerName.toUpperCase();
    final String metaText = "OWNER: $ownerClean · STREAK: $streak DAYS";

    // Painters
    final tp1 = TextPainter(textDirection: TextDirection.ltr);
    tp1.text = TextSpan(
      text: statusText,
      style: GoogleFonts.jetBrainsMono(
        color: semanticColor,
        fontSize: 10.0 * scale,
        fontWeight: FontWeight.w600,
        letterSpacing: 10.0 * scale * 0.06,
      ),
    );
    tp1.layout();

    final tp2 = TextPainter(textDirection: TextDirection.ltr);
    tp2.text = TextSpan(
      text: zoneNameUpper,
      style: GoogleFonts.spaceGrotesk(
        color: const Color(0xFFEBEBEB),
        fontSize: 14.0 * scale,
        fontWeight: FontWeight.w700,
        letterSpacing: 14.0 * scale * 0.04,
      ),
    );
    tp2.layout();

    final tp3 = TextPainter(textDirection: TextDirection.ltr);
    tp3.text = TextSpan(
      text: metaText,
      style: GoogleFonts.jetBrainsMono(
        color: const Color(0xFF888888),
        fontSize: 10.0 * scale,
        fontWeight: FontWeight.w400,
        letterSpacing: 10.0 * scale * 0.06,
      ),
    );
    tp3.layout();

    final double textWidth = max(max(tp1.width, tp2.width), tp3.width);
    final double cardWidth = textWidth + paddingX * 2;
    final double cardHeight = tp1.height + tp2.height + tp3.height + paddingY * 2 + (lineSpacing * 2);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Draw background (#141414 surface) - 0 border-radius
    final cardPaint = Paint()
      ..color = const Color(0xFF141414)
      ..style = PaintingStyle.fill;
    
    final cardRect = Rect.fromLTWH(0, 0, cardWidth, cardHeight);
    canvas.drawRect(cardRect, cardPaint);

    // Draw border (1px solid semantic color)
    final borderPaint = Paint()
      ..color = semanticColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 * scale;
    canvas.drawRect(cardRect, borderPaint);

    // Paint Text Lines
    final double textX = paddingX;
    final double y1 = paddingY;
    final double y2 = y1 + tp1.height + lineSpacing;
    final double y3 = y2 + tp2.height + lineSpacing;

    tp1.paint(canvas, Offset(textX, y1));
    tp2.paint(canvas, Offset(textX, y2));
    tp3.paint(canvas, Offset(textX, y3));

    final picture = recorder.endRecording();
    final img = await picture.toImage(cardWidth.toInt(), cardHeight.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  /// Generate a flat green directional user position pointer
  static Future<BitmapDescriptor> createUserPositionMarker(double pixelRatio) async {
    final double scale = pixelRatio;
    final double size = 32.0 * scale;
    final double center = size / 2;
    final double dotRadius = 9.0 * scale;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Pulsing outer ring (green)
    final ringPaint = Paint()
      ..color = const Color(0x26B8FF00) // rgba(184, 255, 0, 0.15)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(center, center), size / 2, ringPaint);

    // Core green dot
    final dotPaint = Paint()
      ..color = const Color(0xFFB8FF00) // Lime green #B8FF00
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

    // Darker outline for high contrast against maps
    final outlinePaint = Paint()
      ..color = const Color(0xFF0A0A0A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * scale;
    canvas.drawCircle(Offset(center, center), dotRadius, outlinePaint);

    final arrowOutlinePaint = Paint()
      ..color = const Color(0xFF0A0A0A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 * scale;
    canvas.drawPath(arrowPath, arrowOutlinePaint);

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }
}
