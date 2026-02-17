import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../renderer/blueprint_node.dart';
import '../../renderer/render_context.dart';
import '../../renderer/widget_registry.dart';

/// Renders a titled section with an ink-brush underline and vertically stacked children.
///
/// Blueprint JSON:
/// ```json
/// {"type": "section", "title": "This Month", "children": [{"type": "stat_card", "label": "Total", "stat": "count"}]}
/// ```
///
/// - `title` (`String?`, optional): Section heading displayed above a decorative ink-brush underline.
/// - `children` (`List<BlueprintNode>`, optional): Child widgets rendered vertically within the section.
Widget buildSection(BlueprintNode node, RenderContext ctx) {
  final section = node as SectionNode;
  final registry = WidgetRegistry.instance;

  return _SectionWidget(section: section, ctx: ctx, registry: registry);
}

class _SectionWidget extends StatelessWidget {
  final SectionNode section;
  final RenderContext ctx;
  final WidgetRegistry registry;

  const _SectionWidget({
    required this.section,
    required this.ctx,
    required this.registry,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (section.title != null) ...[
          Text(
            section.title!,
            style: TextStyle(
              fontFamily: 'CormorantGaramond',
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: colors.onBackground,
            ),
          ),
          const SizedBox(height: 3),
          CustomPaint(
            size: const Size(double.infinity, 2),
            painter: _InkBrushLinePainter(color: colors.border),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        for (final child in section.children) ...[
          registry.build(child, ctx),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

/// A CustomPainter that draws a slightly wobbly ink-brush underline.
class _InkBrushLinePainter extends CustomPainter {
  final Color color;
  const _InkBrushLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height * 0.5);

    // Subtle wobble — 4 segments with slight vertical variation
    final segW = size.width / 4;
    path.quadraticBezierTo(segW * 0.5, size.height * 0.2, segW, size.height * 0.6);
    path.quadraticBezierTo(segW * 1.5, size.height * 0.9, segW * 2, size.height * 0.4);
    path.quadraticBezierTo(segW * 2.5, size.height * 0.1, segW * 3, size.height * 0.7);
    path.quadraticBezierTo(segW * 3.5, size.height * 1.0, segW * 4, size.height * 0.5);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_InkBrushLinePainter oldDelegate) => color != oldDelegate.color;
}
