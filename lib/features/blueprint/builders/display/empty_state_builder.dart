import 'package:flutter/material.dart';

import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../renderer/blueprint_node.dart';
import '../../renderer/render_context.dart';

Widget buildEmptyState(BlueprintNode node, RenderContext ctx) {
  final empty = node as EmptyStateNode;
  return _EmptyStateWidget(empty: empty);
}

class _EmptyStateWidget extends StatelessWidget {
  final EmptyStateNode empty;

  const _EmptyStateWidget({required this.empty});

  IconData _resolveIcon(String? iconName) {
    return switch (iconName) {
      'list' => PhosphorIcons.listBullets(PhosphorIconsStyle.light),
      'workout' => PhosphorIcons.barbell(PhosphorIconsStyle.light),
      'chart' => PhosphorIcons.chartBar(PhosphorIconsStyle.light),
      'calendar' => PhosphorIcons.calendar(PhosphorIconsStyle.light),
      'note' => PhosphorIcons.notepad(PhosphorIconsStyle.light),
      _ => PhosphorIcons.tray(PhosphorIconsStyle.light),
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _resolveIcon(empty.icon),
              size: 48,
              color: colors.onBackgroundMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            if (empty.title != null)
              Text(
                empty.title!,
                style: TextStyle(
                  fontFamily: 'Karla',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: colors.onBackgroundMuted,
                ),
              ),
            if (empty.subtitle != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                empty.subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Karla',
                  fontSize: 14,
                  color: colors.onBackgroundMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
