import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../renderer/blueprint_node.dart';
import '../../engine/entry_filter.dart';
import '../../engine/expression_evaluator.dart';
import '../../renderer/render_context.dart';

Widget buildStatCard(BlueprintNode node, RenderContext ctx) {
  final card = node as StatCardNode;
  return _StatCardWidget(card: card, ctx: ctx);
}

class _StatCardWidget extends StatelessWidget {
  final StatCardNode card;
  final RenderContext ctx;

  const _StatCardWidget({required this.card, required this.ctx});

  String _computeStat() {
    // Use EntryFilter for unified filtering
    final result = EntryFilter.filter(ctx.entries, card.filter, ctx.screenParams);
    final entries = result.entries;
    final meta = result.meta;

    // If expression is provided, use ExpressionEvaluator
    if (card.expression != null && card.expression!.isNotEmpty) {
      final evaluator = ExpressionEvaluator(
        entries: entries,
        params: {...ctx.screenParams, ...meta},
      );
      final value = evaluator.evaluate(card.expression!);
      if (value == null) return '--';
      if (value == value.truncateToDouble()) return '${value.round()}';
      return value.toStringAsFixed(1);
    }

    // Legacy stat types (backward compat)
    switch (card.stat) {
      case 'count':
        return entries.length.toString();

      case 'this_week':
        final now = DateTime.now();
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
        final count = entries.where((e) {
          final dateStr = e.data['date'] as String?;
          if (dateStr == null) return false;
          final date = DateTime.tryParse(dateStr);
          return date != null && date.isAfter(weekStartDate);
        }).length;
        return count.toString();

      case 'this_month':
        final now = DateTime.now();
        final count = entries.where((e) {
          final dateStr = e.data['date'] as String?;
          if (dateStr == null) return false;
          final date = DateTime.tryParse(dateStr);
          return date != null && date.month == now.month && date.year == now.year;
        }).length;
        return count.toString();

      case 'streak':
        if (entries.isEmpty) return '0';
        final dates = entries
            .map((e) => e.data['date'] as String?)
            .where((d) => d != null)
            .map((d) => DateTime.tryParse(d!))
            .where((d) => d != null)
            .map((d) => DateTime(d!.year, d.month, d.day))
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));

        if (dates.isEmpty) return '0';
        var streak = 0;
        var check = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
        for (final date in dates) {
          if (date == check) {
            streak++;
            check = check.subtract(const Duration(days: 1));
          } else if (date.isBefore(check)) {
            break;
          }
        }
        return streak.toString();

      case 'sum_amount':
        final total = entries.fold<num>(0, (sum, e) {
          final a = e.data['amount'] as num?;
          return sum + (a ?? 0);
        });
        if (total == 0) return '--';
        return total.toStringAsFixed(total.truncateToDouble() == total ? 0 : 2);

      case 'avg_duration':
        final durations = entries
            .map((e) => e.data['duration'] as num?)
            .where((d) => d != null)
            .toList();
        if (durations.isEmpty) return '--';
        final avg = durations.reduce((a, b) => a! + b!)! / durations.length;
        return '${avg.round()}';

      case 'total_duration':
        final total = entries.fold<num>(0, (sum, e) {
          final d = e.data['duration'] as num?;
          return sum + (d ?? 0);
        });
        if (total == 0) return '--';
        return '${total.round()}';

      case 'sum_field':
        final fieldKey = meta['_sumField'] as String? ?? 'amount';
        final suffix = meta['_suffix'] as String? ?? '';
        final total = entries.fold<num>(0, (sum, e) {
          final v = e.data[fieldKey] as num?;
          return sum + (v ?? 0);
        });
        if (total == 0) return '--';
        final formatted = total.truncateToDouble() == total
            ? '${total.round()}'
            : total.toStringAsFixed(1);
        return '$formatted$suffix';

      case 'param_value':
        final paramKey = meta['_paramKey'] as String?;
        final suffix = meta['_suffix'] as String? ?? '';
        if (paramKey == null) return '--';
        final value = ctx.screenParams[paramKey];
        if (value == null) return '--';
        return '$value$suffix';

      default:
        return '--';
    }
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
