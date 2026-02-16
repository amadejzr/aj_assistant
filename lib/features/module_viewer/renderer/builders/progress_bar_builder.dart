import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../blueprint_node.dart';
import '../expression_evaluator.dart';
import '../render_context.dart';

Widget buildProgressBar(BlueprintNode node, RenderContext ctx) {
  final bar = node as ProgressBarNode;
  return _ProgressBarWidget(bar: bar, ctx: ctx);
}

class _ProgressBarWidget extends StatelessWidget {
  final ProgressBarNode bar;
  final RenderContext ctx;

  const _ProgressBarWidget({required this.bar, required this.ctx});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    num? value;
    if (bar.expression != null) {
      final evaluator = ExpressionEvaluator(
        entries: ctx.entries,
        params: ctx.screenParams,
      );
      value = evaluator.evaluate(bar.expression!);
    }

    final percent = (value ?? 0).toDouble().clamp(0.0, 100.0);
    final isPercentage = bar.format == 'percentage';
    final displayValue = isPercentage
        ? '${percent.round()}%'
        : '${value?.round() ?? 0}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (bar.label != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    bar.label!,
                    style: GoogleFonts.karla(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: colors.onBackgroundMuted,
                    ),
                  ),
                  Text(
                    displayValue,
                    style: GoogleFonts.karla(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.onBackground,
                    ),
                  ),
                ],
              ),
            ),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percent / 100,
              minHeight: 8,
              backgroundColor: colors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                percent >= 100 ? colors.error : colors.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
