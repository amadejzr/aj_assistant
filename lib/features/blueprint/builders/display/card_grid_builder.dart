import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../renderer/blueprint_node.dart';
import '../../renderer/render_context.dart';

/// Renders a 2-column grid of tappable cards, one per enum option, showing the entry count for each.
///
/// Blueprint JSON:
/// ```json
/// {"type": "card_grid", "fieldKey": "category", "action": {"screen": "category_detail", "paramKey": "category"}}
/// ```
///
/// - `fieldKey` (`String`, required): Schema field key whose enum options populate the grid cards.
/// - `action` (`Map<String, dynamic>`, optional): Navigation action on card tap, with `screen` and optional `paramKey`.
Widget buildCardGrid(BlueprintNode node, RenderContext ctx) {
  final grid = node as CardGridNode;
  return _CardGridWidget(grid: grid, ctx: ctx);
}

class _CardGridWidget extends StatelessWidget {
  final CardGridNode grid;
  final RenderContext ctx;

  const _CardGridWidget({required this.grid, required this.ctx});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final options = (grid.properties['options'] as List?)?.cast<String>() ?? [];

    if (options.isEmpty) {
      return const SizedBox.shrink();
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.sm,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.3,
      ),
      itemCount: options.length,
      itemBuilder: (context, index) {
        final option = options[index];
        final count = ctx.entries
            .where((e) => e.data[grid.fieldKey]?.toString() == option)
            .length;

        return _ActivityCard(
          label: option,
          count: count,
          colors: colors,
          onTap: () {
            final action = grid.action;
            final screen = action['screen'] as String?;
            final paramKey = action['paramKey'] as String? ?? grid.fieldKey;
            if (screen != null) {
              ctx.onNavigateToScreen(
                screen,
                params: {...ctx.screenParams, paramKey: option},
              );
            }
          },
        );
      },
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final String label;
  final int count;
  final AppColors colors;
  final VoidCallback onTap;

  const _ActivityCard({
    required this.label,
    required this.count,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'CormorantGaramond',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: colors.onBackground,
                height: 1.2,
              ),
            ),
            Row(
              children: [
                Text(
                  '$count',
                  style: TextStyle(
                    fontFamily: 'Karla',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.accent,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  count == 1 ? 'entry' : 'entries',
                  style: TextStyle(
                    fontFamily: 'Karla',
                    fontSize: 12,
                    color: colors.onBackgroundMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
