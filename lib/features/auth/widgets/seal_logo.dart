import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SealLogo extends StatelessWidget {
  final Color color;
  final Color textColor;
  final double size;

  const SealLogo({
    super.key,
    required this.color,
    required this.textColor,
    this.size = 58,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _SealPainter(color: color),
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Text(
            'AJ',
            style: GoogleFonts.cormorantGaramond(
              fontSize: size * 0.38,
              fontWeight: FontWeight.w700,
              color: textColor,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

/// Vermillion seal — slightly irregular circle like a hanko stamp
class _SealPainter extends CustomPainter {
  final Color color;

  _SealPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Slightly irregular circle with subtle wobble
    final path = Path();
    const segments = 36;
    for (var i = 0; i <= segments; i++) {
      final angle = (i / segments) * 2 * math.pi;
      final wobble = 1.0 +
          math.sin(angle * 5) * 0.015 +
          math.cos(angle * 3) * 0.01;
      final r = radius * wobble;
      final point = Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();

    canvas.drawPath(path, Paint()..color = color);

    // Inner ring for stamp authenticity
    final innerRing = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, radius * 0.78, innerRing);
  }

  @override
  bool shouldRepaint(covariant _SealPainter oldDelegate) =>
      color != oldDelegate.color;
}
