import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class PaperBackground extends StatelessWidget {
  final AppColors colors;

  const PaperBackground({super.key, required this.colors});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: CustomPaint(
        painter: _SketchbookPainter(colors: colors),
      ),
    );
  }
}

class _SketchbookPainter extends CustomPainter {
  final AppColors colors;

  _SketchbookPainter({required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    final w = size.width;
    final h = size.height;

    // Base paper fill
    canvas.drawRect(Offset.zero & size, Paint()..color = colors.background);

    // — Hand-drawn page border (wobbly pencil rectangle) —
    final borderPaint = Paint()
      ..color = colors.onBackgroundMuted.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;

    final margin = w * 0.07;
    final borderPath = Path();
    const wobbleSegments = 30;
    // Top edge
    for (var i = 0; i <= wobbleSegments; i++) {
      final t = i / wobbleSegments;
      final x = margin + t * (w - margin * 2);
      final y = margin + rng.nextDouble() * 1.5 - 0.75;
      if (i == 0) {
        borderPath.moveTo(x, y);
      } else {
        borderPath.lineTo(x, y);
      }
    }
    // Right edge
    for (var i = 0; i <= wobbleSegments; i++) {
      final t = i / wobbleSegments;
      final x = w - margin + rng.nextDouble() * 1.5 - 0.75;
      final y = margin + t * (h - margin * 2);
      borderPath.lineTo(x, y);
    }
    // Bottom edge
    for (var i = wobbleSegments; i >= 0; i--) {
      final t = i / wobbleSegments;
      final x = margin + t * (w - margin * 2);
      final y = h - margin + rng.nextDouble() * 1.5 - 0.75;
      borderPath.lineTo(x, y);
    }
    // Left edge
    for (var i = wobbleSegments; i >= 0; i--) {
      final t = i / wobbleSegments;
      final x = margin + rng.nextDouble() * 1.5 - 0.75;
      final y = margin + t * (h - margin * 2);
      borderPath.lineTo(x, y);
    }
    canvas.drawPath(borderPath, borderPaint);

    // — Cross-hatching in top-right corner —
    final hatchPaint = Paint()
      ..color = colors.onBackgroundMuted.withValues(alpha: 0.07)
      ..strokeWidth = 0.5
      ..strokeCap = StrokeCap.round;
    final hatchX = w * 0.68;
    final hatchY = h * 0.04;
    final hatchW = w * 0.26;
    final hatchH = h * 0.1;
    // Diagonal lines ///
    for (var i = 0; i < 18; i++) {
      final offset = i * (hatchW / 18);
      final wobX = rng.nextDouble() * 1.5;
      final wobY = rng.nextDouble() * 1.5;
      canvas.drawLine(
        Offset(hatchX + offset + wobX, hatchY + wobY),
        Offset(hatchX + offset - hatchH * 0.4 + wobX, hatchY + hatchH + wobY),
        hatchPaint,
      );
    }
    // Cross lines \\\
    for (var i = 0; i < 12; i++) {
      final offset = i * (hatchW / 12);
      final wobX = rng.nextDouble() * 1.5;
      final wobY = rng.nextDouble() * 1.5;
      canvas.drawLine(
        Offset(hatchX + offset - hatchH * 0.3 + wobX, hatchY + wobY),
        Offset(hatchX + offset + wobX, hatchY + hatchH + wobY),
        hatchPaint,
      );
    }

    // — Pencil shading patch — light diagonal strokes, bottom-left area —
    final shadePaint = Paint()
      ..color = colors.onBackgroundMuted.withValues(alpha: 0.05)
      ..strokeWidth = 0.4;
    for (var i = 0; i < 25; i++) {
      final sx = w * 0.03 + rng.nextDouble() * w * 0.25;
      final sy = h * 0.78 + rng.nextDouble() * h * 0.14;
      final len = 8 + rng.nextDouble() * 18;
      canvas.drawLine(
        Offset(sx, sy),
        Offset(sx + len * 0.7, sy - len * 0.7),
        shadePaint,
      );
    }

    // — Hand-drawn spiral doodle — upper-left margin area —
    final spiralPaint = Paint()
      ..color = colors.onBackgroundMuted.withValues(alpha: 0.09)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;
    final spiralPath = Path();
    final cx = w * 0.13;
    final cy = h * 0.13;
    for (var i = 0; i < 120; i++) {
      final angle = i * 0.15;
      final r = 2.0 + i * 0.15;
      final px = cx + r * math.cos(angle);
      final py = cy + r * math.sin(angle);
      if (i == 0) {
        spiralPath.moveTo(px, py);
      } else {
        spiralPath.lineTo(px, py);
      }
    }
    canvas.drawPath(spiralPath, spiralPaint);

    // — Ink pen circle doodle — bottom-right, like someone idly drew it —
    final doodlePaint = Paint()
      ..color = colors.accent.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final doodlePath = Path();
    final dcx = w * 0.85;
    final dcy = h * 0.85;
    for (var i = 0; i <= 32; i++) {
      final angle = (i / 32) * 2 * math.pi * 1.15; // slightly overshoot
      final r = w * 0.06 + rng.nextDouble() * 2.0 - 1.0;
      final px = dcx + r * math.cos(angle);
      final py = dcy + r * math.sin(angle);
      if (i == 0) {
        doodlePath.moveTo(px, py);
      } else {
        doodlePath.lineTo(px, py);
      }
    }
    canvas.drawPath(doodlePath, doodlePaint);

    // — Scattered pencil marks — quick short strokes across the page —
    final pencilPaint = Paint()
      ..color = colors.onBackgroundMuted.withValues(alpha: 0.06)
      ..strokeWidth = 0.5
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 35; i++) {
      final x = rng.nextDouble() * w;
      final y = rng.nextDouble() * h;
      final len = 3.0 + rng.nextDouble() * 8.0;
      final angle = rng.nextDouble() * math.pi * 0.5 - math.pi * 0.25;
      canvas.drawLine(
        Offset(x, y),
        Offset(x + len * math.cos(angle), y + len * math.sin(angle)),
        pencilPaint,
      );
    }

    // — Ink dots — like pen tapped on paper —
    final inkDotPaint = Paint()
      ..color = colors.onBackgroundMuted.withValues(alpha: 0.12);
    for (var i = 0; i < 8; i++) {
      final x = rng.nextDouble() * w;
      final y = rng.nextDouble() * h;
      final r = 0.8 + rng.nextDouble() * 1.8;
      canvas.drawCircle(Offset(x, y), r, inkDotPaint);
    }

    // — Small arrow sketch — like pointing at something, mid-right margin —
    final arrowPaint = Paint()
      ..color = colors.onBackgroundMuted.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;
    final ax = w * 0.9;
    final ay = h * 0.5;
    canvas.drawLine(Offset(ax, ay), Offset(ax, ay + 30), arrowPaint);
    canvas.drawLine(Offset(ax, ay + 30), Offset(ax - 5, ay + 24), arrowPaint);
    canvas.drawLine(Offset(ax, ay + 30), Offset(ax + 5, ay + 24), arrowPaint);

    // — Faint eraser smudge — like something was rubbed out —
    final smudgePaint = Paint()
      ..color = colors.surfaceVariant.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.6, h * 0.7),
        width: w * 0.12,
        height: h * 0.03,
      ),
      smudgePaint,
    );

    // — Geometric sketch elements — squares, circles, lines —

    // Wobbly square — upper-center area, ~35px, rotated 5deg
    final squarePaint1 = Paint()
      ..color = colors.onBackgroundMuted.withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;
    canvas.save();
    canvas.translate(w * 0.48, h * 0.06);
    canvas.rotate(5 * math.pi / 180);
    final sq1 = Path();
    const sq1Size = 35.0;
    sq1.moveTo(rng.nextDouble() * 1.2, rng.nextDouble() * 1.2);
    sq1.lineTo(sq1Size + rng.nextDouble() * 1.2, rng.nextDouble() * 1.2 - 0.5);
    sq1.lineTo(sq1Size + rng.nextDouble() * 1.2 + 0.5, sq1Size + rng.nextDouble() * 1.2);
    sq1.lineTo(rng.nextDouble() * 1.2 - 0.5, sq1Size + rng.nextDouble() * 1.2 + 0.3);
    sq1.close();
    canvas.drawPath(sq1, squarePaint1);
    canvas.restore();

    // Wobbly square — lower-left area, ~22px, rotated -8deg
    final squarePaint2 = Paint()
      ..color = colors.onBackgroundMuted.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..strokeCap = StrokeCap.round;
    canvas.save();
    canvas.translate(w * 0.08, h * 0.72);
    canvas.rotate(-8 * math.pi / 180);
    final sq2 = Path();
    const sq2Size = 22.0;
    sq2.moveTo(rng.nextDouble() * 1.0, rng.nextDouble() * 1.0);
    sq2.lineTo(sq2Size + rng.nextDouble() * 1.0, rng.nextDouble() * 1.0 - 0.4);
    sq2.lineTo(sq2Size + rng.nextDouble() * 1.0 + 0.3, sq2Size + rng.nextDouble() * 1.0);
    sq2.lineTo(rng.nextDouble() * 1.0 - 0.3, sq2Size + rng.nextDouble() * 1.0 + 0.2);
    sq2.close();
    canvas.drawPath(sq2, squarePaint2);
    canvas.restore();

    // Sketch circle — mid-left, ~12px radius, wobbly line segments
    final circlePaint1 = Paint()
      ..color = colors.onBackgroundMuted.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..strokeCap = StrokeCap.round;
    final circlePath1 = Path();
    final ccx1 = w * 0.1;
    final ccy1 = h * 0.48;
    const cRadius1 = 12.0;
    for (var i = 0; i <= 24; i++) {
      final angle = (i / 24) * 2 * math.pi * 1.05;
      final r = cRadius1 + rng.nextDouble() * 1.4 - 0.7;
      final px = ccx1 + r * math.cos(angle);
      final py = ccy1 + r * math.sin(angle);
      if (i == 0) {
        circlePath1.moveTo(px, py);
      } else {
        circlePath1.lineTo(px, py);
      }
    }
    canvas.drawPath(circlePath1, circlePaint1);

    // Sketch circle — upper-right, ~8px radius, accent color
    final circlePaint2 = Paint()
      ..color = colors.accent.withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;
    final circlePath2 = Path();
    final ccx2 = w * 0.88;
    final ccy2 = h * 0.18;
    const cRadius2 = 8.0;
    for (var i = 0; i <= 20; i++) {
      final angle = (i / 20) * 2 * math.pi * 1.08;
      final r = cRadius2 + rng.nextDouble() * 1.0 - 0.5;
      final px = ccx2 + r * math.cos(angle);
      final py = ccy2 + r * math.sin(angle);
      if (i == 0) {
        circlePath2.moveTo(px, py);
      } else {
        circlePath2.lineTo(px, py);
      }
    }
    canvas.drawPath(circlePath2, circlePaint2);

    // Geometric lines — diagonal line, lower-right
    final geoLinePaint = Paint()
      ..color = colors.onBackgroundMuted.withValues(alpha: 0.08)
      ..strokeWidth = 0.7
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.78, h * 0.88),
      Offset(w * 0.78 + 28, h * 0.88 - 20),
      geoLinePaint,
    );

    // Short horizontal line — top area
    final geoLinePaint2 = Paint()
      ..color = colors.onBackgroundMuted.withValues(alpha: 0.07)
      ..strokeWidth = 0.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.32, h * 0.03),
      Offset(w * 0.32 + 18, h * 0.03),
      geoLinePaint2,
    );

    // Parallel short lines — mid-right
    final geoLinePaint3 = Paint()
      ..color = colors.onBackgroundMuted.withValues(alpha: 0.09)
      ..strokeWidth = 0.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.92, h * 0.38),
      Offset(w * 0.92 + 14, h * 0.38),
      geoLinePaint3,
    );
    canvas.drawLine(
      Offset(w * 0.92, h * 0.38 + 4),
      Offset(w * 0.92 + 14, h * 0.38 + 4),
      geoLinePaint3,
    );
    canvas.drawLine(
      Offset(w * 0.92, h * 0.38 + 8),
      Offset(w * 0.92 + 10, h * 0.38 + 8),
      geoLinePaint3,
    );
  }

  @override
  bool shouldRepaint(covariant _SketchbookPainter oldDelegate) => false;
}
