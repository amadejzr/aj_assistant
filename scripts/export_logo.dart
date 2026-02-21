import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

/// Exports the AJ seal logo as a 1024x1024 PNG for use as the app icon.
///
/// Run from the scripts directory:
///   dart run export_logo.dart
///
/// Output: ../assets/app_icon.png
void main() {
  const size = 1024;
  const center = size / 2;
  const radius = size * 0.40; // seal radius relative to canvas

  // Colors — vermillion accent from app_colors.dart
  const sealR = 0xD9, sealG = 0x4E, sealB = 0x33;

  // Transparent background (for flexible use)
  final image = img.Image(width: size, height: size, numChannels: 4);

  // --- Draw the seal (slightly irregular circle with wobble) ---
  _fillSeal(image, center, center, radius, sealR, sealG, sealB);

  // --- Draw the inner ring ---
  _drawRing(
    image,
    center,
    center,
    radius * 0.78,
    strokeWidth: size * 0.003,
    r: sealR,
    g: sealG,
    b: sealB,
    a: 77, // ~0.3 opacity
  );

  // --- Draw "AJ" text ---
  // Using the built-in bitmap font at a large size
  // For the best result, we draw "A" and "J" as thick stroked paths
  _drawAJ(image, center, center, radius * 0.55, sealR, sealG, sealB);

  // --- Save ---
  final outputDir = Directory('../assets');
  if (!outputDir.existsSync()) outputDir.createSync(recursive: true);

  final outputPath = '../assets/app_icon.png';
  File(outputPath).writeAsBytesSync(img.encodePng(image));
  print('Exported logo to $outputPath (${size}x$size)');
  print('Use this with flutter_launcher_icons to generate platform icons.');
}

/// Fills the seal shape — a slightly irregular circle matching _SealPainter.
void _fillSeal(
  img.Image image,
  double cx,
  double cy,
  double radius,
  int r,
  int g,
  int b,
) {
  final size = image.width;
  final color = img.ColorRgba8(r, g, b, 255);

  // For each pixel, check if it's inside the wobbled circle
  for (var py = 0; py < size; py++) {
    for (var px = 0; px < size; px++) {
      final dx = px - cx;
      final dy = py - cy;
      final dist = math.sqrt(dx * dx + dy * dy);
      final angle = math.atan2(dy, dx);

      // Same wobble formula as _SealPainter
      final wobble =
          1.0 + math.sin(angle * 5) * 0.015 + math.cos(angle * 3) * 0.01;
      final edgeRadius = radius * wobble;

      if (dist <= edgeRadius) {
        image.setPixel(px, py, color);
      } else if (dist <= edgeRadius + 1.5) {
        // Anti-alias the edge
        final alpha = ((edgeRadius + 1.5 - dist) / 1.5 * 255).round();
        image.setPixel(px, py, img.ColorRgba8(r, g, b, alpha));
      }
    }
  }
}

/// Draws a ring (stroke-only circle).
void _drawRing(
  img.Image image,
  double cx,
  double cy,
  double radius, {
  required double strokeWidth,
  required int r,
  required int g,
  required int b,
  required int a,
}) {
  final size = image.width;
  final inner = radius - strokeWidth / 2;
  final outer = radius + strokeWidth / 2;

  for (var py = 0; py < size; py++) {
    for (var px = 0; px < size; px++) {
      final dx = px - cx;
      final dy = py - cy;
      final dist = math.sqrt(dx * dx + dy * dy);

      if (dist >= inner && dist <= outer) {
        // Blend with existing pixel
        final existing = image.getPixel(px, py);
        final existingA = existing.a.toInt();
        if (existingA > 0) {
          // Composite the ring color over the existing seal color
          final blendedR = ((existing.r.toInt() * (255 - a) + r * a) / 255)
              .round();
          final blendedG = ((existing.g.toInt() * (255 - a) + g * a) / 255)
              .round();
          final blendedB = ((existing.b.toInt() * (255 - a) + b * a) / 255)
              .round();
          image.setPixel(
            px,
            py,
            img.ColorRgba8(blendedR, blendedG, blendedB, existingA),
          );
        }
      }
    }
  }
}

/// Draws "AJ" using vector-style thick strokes.
void _drawAJ(
  img.Image image,
  double cx,
  double cy,
  double textHeight,
  int bgR,
  int bgG,
  int bgB,
) {
  // Text color = background of seal (vermillion), drawn as knockout
  // Actually for the icon, text should contrast with seal — use white or
  // the background color. The app uses textColor = background (dark charcoal
  // on dark theme). For the icon PNG let's use white for versatility.
  const tr = 255, tg = 255, tb = 255;

  final strokeW = textHeight * 0.12;

  // Letter metrics
  final letterH = textHeight * 0.7;
  final letterW = letterH * 0.55;
  final gap = letterW * 0.15; // gap between A and J
  final totalW = letterW * 2 + gap;

  // Top-left of the text block
  final startX = cx - totalW / 2;
  final startY = cy - letterH / 2;

  // --- Draw letter "A" ---
  final aPeakX = startX + letterW / 2;
  final aPeakY = startY;
  final aLeftX = startX;
  final aRightX = startX + letterW;
  final aBottomY = startY + letterH;

  // Left leg of A
  _drawThickLine(image, aPeakX, aPeakY, aLeftX, aBottomY, strokeW, tr, tg, tb);
  // Right leg of A
  _drawThickLine(image, aPeakX, aPeakY, aRightX, aBottomY, strokeW, tr, tg, tb);
  // Crossbar of A
  final crossY = startY + letterH * 0.55;
  final crossLeftX = aLeftX + letterW * 0.18;
  final crossRightX = aRightX - letterW * 0.18;
  _drawThickLine(
    image,
    crossLeftX,
    crossY,
    crossRightX,
    crossY,
    strokeW * 0.8,
    tr,
    tg,
    tb,
  );

  // --- Draw letter "J" ---
  final jStartX = startX + letterW + gap;
  final jTopY = startY;
  final jBottomY = startY + letterH;
  final jMidX = jStartX + letterW / 2;

  // Top horizontal bar of J
  _drawThickLine(
    image,
    jStartX,
    jTopY,
    jStartX + letterW,
    jTopY,
    strokeW,
    tr,
    tg,
    tb,
  );
  // Vertical stem of J
  _drawThickLine(
    image,
    jMidX,
    jTopY,
    jMidX,
    jBottomY - letterH * 0.2,
    strokeW,
    tr,
    tg,
    tb,
  );
  // Hook of J (curve at bottom)
  final hookCenterX = jStartX + letterW * 0.25;
  final hookCenterY = jBottomY - letterH * 0.2;
  final hookRadius = letterW * 0.25;
  _drawArc(
    image,
    hookCenterX,
    hookCenterY,
    hookRadius,
    0, // start angle (right)
    math.pi, // sweep (bottom half)
    strokeW,
    tr,
    tg,
    tb,
  );
}

/// Draws a thick line between two points.
void _drawThickLine(
  img.Image image,
  double x1,
  double y1,
  double x2,
  double y2,
  double thickness,
  int r,
  int g,
  int b,
) {
  final color = img.ColorRgba8(r, g, b, 255);
  final halfT = thickness / 2;

  final minX = math.min(x1, x2) - halfT - 2;
  final maxX = math.max(x1, x2) + halfT + 2;
  final minY = math.min(y1, y2) - halfT - 2;
  final maxY = math.max(y1, y2) + halfT + 2;

  final dx = x2 - x1;
  final dy = y2 - y1;
  final len = math.sqrt(dx * dx + dy * dy);
  if (len == 0) return;

  for (var py = minY.floor(); py <= maxY.ceil(); py++) {
    for (var px = minX.floor(); px <= maxX.ceil(); px++) {
      if (px < 0 || px >= image.width || py < 0 || py >= image.height) continue;

      // Distance from point to line segment
      final t = ((px - x1) * dx + (py - y1) * dy) / (len * len);
      final ct = t.clamp(0.0, 1.0);
      final closestX = x1 + ct * dx;
      final closestY = y1 + ct * dy;
      final dist = math.sqrt(
        (px - closestX) * (px - closestX) + (py - closestY) * (py - closestY),
      );

      if (dist <= halfT) {
        image.setPixel(px, py, color);
      } else if (dist <= halfT + 1.2) {
        final alpha = ((halfT + 1.2 - dist) / 1.2 * 255).round();
        final existing = image.getPixel(px, py);
        if (existing.a.toInt() > alpha) continue;
        image.setPixel(px, py, img.ColorRgba8(r, g, b, alpha));
      }
    }
  }
}

/// Draws a thick arc.
void _drawArc(
  img.Image image,
  double cx,
  double cy,
  double radius,
  double startAngle,
  double sweep,
  double thickness,
  int r,
  int g,
  int b,
) {
  final steps = (sweep * radius).round().clamp(20, 200);
  for (var i = 0; i < steps; i++) {
    final a1 = startAngle + sweep * (i / steps);
    final a2 = startAngle + sweep * ((i + 1) / steps);
    final x1 = cx + radius * math.cos(a1);
    final y1 = cy + radius * math.sin(a1);
    final x2 = cx + radius * math.cos(a2);
    final y2 = cy + radius * math.sin(a2);
    _drawThickLine(image, x1, y1, x2, y2, thickness, r, g, b);
  }
}
