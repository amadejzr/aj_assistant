import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../renderer/blueprint_node.dart';
import '../../engine/expression_evaluator.dart';
import '../../renderer/render_context.dart';

/// Renders a labeled linear progress bar with a value computed from an expression.
///
/// Blueprint JSON:
/// ```json
/// {"type": "progress_bar", "label": "Budget Used", "expression": "percentage(sum(amount), settings.monthlyBudget)", "format": "percentage"}
/// ```
///
/// - `label` (`String?`, optional): Display label shown above the progress bar.
/// - `expression` (`String?`, optional): Expression string evaluated to produce the progress value (0-100).
/// - `format` (`String?`, optional): Output format. Use `"percentage"` to display as percent; otherwise shows raw value.
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
        params: {...ctx.module.settings, ...ctx.screenParams},
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
                    style: TextStyle(
                      fontFamily: 'Karla',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: colors.onBackgroundMuted,
                    ),
                  ),
                  Text(
                    displayValue,
                    style: TextStyle(
                      fontFamily: 'Karla',
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
