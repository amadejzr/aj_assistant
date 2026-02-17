import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/models/entry.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../renderer/blueprint_node.dart';
import '../../engine/entry_filter.dart';
import '../../engine/expression_evaluator.dart';
import '../../renderer/render_context.dart';

/// Renders a chart (pie, donut, or bar) by grouping entries and computing aggregates.
///
/// Blueprint JSON:
/// ```json
/// {"type": "chart", "chartType": "donut", "groupBy": "category", "aggregate": "sum(amount)"}
/// ```
///
/// - `chartType` (`String`, optional): Chart visualization type. One of `"pie"`, `"donut"`, or `"bar"`. Defaults to `"donut"`.
/// - `groupBy` (`String?`, optional): Entry field key used to group data into chart segments.
/// - `aggregate` (`String?`, optional): Expression string evaluated per group (e.g., `"sum(amount)"`). Defaults to count if omitted.
/// - `filter` (`dynamic`, optional): Entry filter to scope which entries are included in the chart.
Widget buildChart(BlueprintNode node, RenderContext ctx) {
  final chart = node as ChartNode;
  return _ChartWidget(chart: chart, ctx: ctx);
}

class _ChartWidget extends StatelessWidget {
  final ChartNode chart;
  final RenderContext ctx;

  const _ChartWidget({required this.chart, required this.ctx});

  static const _palette = [
    Color(0xFFD94E33), // vermillion (hanko red)
    Color(0xFF4A4A48), // charcoal (sumi ink)
    Color(0xFF8B6E4E), // warm brown (walnut ink)
    Color(0xFFC9A84C), // warm gold (aged paper)
    Color(0xFF5B8C5A), // sage green
    Color(0xFFCC7744), // copper
    Color(0xFF7A8B8B), // warm gray (stone)
    Color(0xFF9E6B6B), // dusty rose
  ];

  Map<String, num> _groupData() {
    // Filter entries
    final filtered = chart.filter != null
        ? EntryFilter.filter(ctx.entries, chart.filter, ctx.screenParams).entries
        : ctx.entries;

    final groupBy = chart.groupBy;
    if (groupBy == null) return {};

    // Group entries by field value
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final entry in filtered) {
      final key = entry.data[groupBy]?.toString() ?? 'Other';
      groups.putIfAbsent(key, () => []).add(entry.data);
    }

    // Compute aggregate per group
    final result = <String, num>{};
    for (final entry in groups.entries) {
      final groupEntries = entry.value;

      if (chart.aggregate != null && chart.aggregate!.isNotEmpty) {
        final syntheticEntries = groupEntries.map((data) {
          return Entry(id: '', data: data);
        }).toList();

        final evaluator = ExpressionEvaluator(
          entries: syntheticEntries,
          params: {...ctx.module.settings, ...ctx.screenParams},
        );
        result[entry.key] = evaluator.evaluate(chart.aggregate!) ?? 0;
      } else {
        result[entry.key] = groupEntries.length;
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final data = _groupData();

    if (data.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Center(
          child: Text(
            'No data to display',
            style: TextStyle(
              fontFamily: 'Karla',
              color: colors.onBackgroundMuted,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    return switch (chart.chartType) {
      'pie' || 'donut' => _buildPieChart(data, colors),
      'bar' => _buildBarChart(data, colors),
      _ => _buildPieChart(data, colors),
    };
  }

  Widget _buildPieChart(Map<String, num> data, dynamic colors) {
    final total = data.values.fold<num>(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

    final isDonut = chart.chartType == 'donut';
    final entries = data.entries.toList();

    final sections = entries.asMap().entries.map((e) {
      final color = _palette[e.key % _palette.length];
      final percent = e.value.value / total * 100;
      return PieChartSectionData(
        value: e.value.value.toDouble(),
        color: color,
        radius: isDonut ? 24 : 48,
        title: percent >= 5 ? '${percent.round()}%' : '',
        titleStyle: TextStyle(
          fontFamily: 'Karla',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      );
    }).toList();

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: isDonut ? 40 : 0,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _buildLegend(entries, colors),
      ],
    );
  }

  Widget _buildBarChart(Map<String, num> data, dynamic colors) {
    final entries = data.entries.toList();
    final maxVal = entries.map((e) => e.value).reduce(math.max).toDouble();

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxVal * 1.2,
              barGroups: entries.asMap().entries.map((e) {
                final color = _palette[e.key % _palette.length];
                return BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: e.value.value.toDouble(),
                      color: color,
                      width: 20,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ],
                );
              }).toList(),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= entries.length) {
                        return const SizedBox.shrink();
                      }
                      final label = entries[idx].key;
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          label.length > 8
                              ? '${label.substring(0, 7)}…'
                              : label,
                          style: TextStyle(
                            fontFamily: 'Karla',
                            fontSize: 11,
                            color: colors.onBackgroundMuted,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: false),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }

  Widget _buildLegend(
    List<MapEntry<String, num>> entries,
    dynamic colors,
  ) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: entries.asMap().entries.map((e) {
        final color = _palette[e.key % _palette.length];
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              e.value.key,
              style: TextStyle(
                fontFamily: 'Karla',
                fontSize: 12,
                color: colors.onBackgroundMuted,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

