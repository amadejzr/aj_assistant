import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../renderer/blueprint_node.dart';
import '../../renderer/render_context.dart';

Widget buildBadge(BlueprintNode node, RenderContext ctx) {
  final badge = node as BadgeNode;
  return _BadgeWidget(badge: badge, ctx: ctx);
}

class _BadgeWidget extends StatelessWidget {
  final BadgeNode badge;
  final RenderContext ctx;

  const _BadgeWidget({required this.badge, required this.ctx});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // Resolve expression if present, otherwise use text
    final displayText = badge.expression != null
        ? (ctx.resolvedExpressions[badge.expression]?.toString() ??
            badge.text)
        : badge.text;

    final (bgColor, fgColor) = _variantColors(badge.variant, colors);

    return Transform.rotate(
      angle: -2 * math.pi / 180, // -2 degrees, hanko seal style
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          displayText,
          style: TextStyle(
            fontFamily: 'CormorantGaramond',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: fgColor,
          ),
        ),
      ),
    );
  }

  (Color bg, Color fg) _variantColors(String variant, dynamic colors) {
    return switch (variant) {
      'accent' => (colors.accent, Colors.white),
      'success' => (const Color(0xFF2E7D32), Colors.white),
      'warning' => (const Color(0xFFF57F17), Colors.white),
      _ => (colors.border, colors.onBackground),
    };
  }
}
