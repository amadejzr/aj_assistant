import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../renderer/blueprint_node.dart';
import '../../renderer/render_context.dart';

/// Renders a stat card showing a computed value from entry data.
///
/// Blueprint JSON:
/// ```json
/// {"type": "stat_card", "label": "Total", "stat": "count", "expression": "sum(amount)", "format": "currency"}
/// ```
///
/// - `label` (`String`, required): Display label shown above the computed value.
/// - `stat` (`String`, required): Legacy stat type (e.g., `"count"`, `"streak"`, `"sum_amount"`, `"this_week"`, `"this_month"`, `"avg_duration"`, `"total_duration"`, `"sum_field"`, `"param_value"`).
/// - `expression` (`String?`, optional): Expression string evaluated by `ExpressionEvaluator` for dynamic computation.
/// - `format` (`String?`, optional): Output format hint (e.g., `"minutes"`, `"currency"`).
/// - `filter` (`dynamic`, optional): Entry filter to scope which entries are included in the computation.
Widget buildStatCard(BlueprintNode node, RenderContext ctx) {
  final card = node as StatCardNode;
  return _StatCardWidget(card: card, ctx: ctx);
}

class _StatCardWidget extends StatelessWidget {
  final StatCardNode card;
  final RenderContext ctx;

  const _StatCardWidget({required this.card, required this.ctx});

  String _computeStat() {
    // SQL source path
    final source = card.properties['source'] as String?;
    final valueKey = card.properties['valueKey'] as String?;
    if (source != null && valueKey != null) {
      final rows = ctx.queryResults[source];
      if (rows == null || rows.isEmpty) return '--';
      final value = rows[0][valueKey];
      if (value == null) return '--';
      if (value is num) {
        if (value == value.truncateToDouble()) return '${value.round()}';
        return value.toStringAsFixed(1);
      }
      return value.toString();
    }

    // Use cached resolvedExpressions
    if (card.expression != null &&
        card.expression!.isNotEmpty &&
        ctx.resolvedExpressions.containsKey(card.expression)) {
      final value = ctx.resolvedExpressions[card.expression] as num?;
      if (value == null) return '--';
      if (value == value.truncateToDouble()) return '${value.round()}';
      return value.toStringAsFixed(1);
    }

    return '--';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final value = _computeStat();

    final suffix = card.format == 'minutes' ? ' min' : '';
    final hasAccent = card.properties['accent'] == true;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.surface,
            Color.lerp(colors.surface, colors.background, 0.3)!,
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          if (hasAccent)
            Container(width: 3, color: colors.accent),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.label.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Karla',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colors.onBackgroundMuted,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '$value$suffix',
                    style: TextStyle(
                      fontFamily: 'CormorantGaramond',
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: colors.onBackground,
                      height: 1.1,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
