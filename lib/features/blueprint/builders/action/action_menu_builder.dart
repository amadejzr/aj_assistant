import 'package:flutter/material.dart';

import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../engine/action_dispatcher.dart';
import '../../renderer/blueprint_node.dart';
import '../../renderer/render_context.dart';

Widget buildActionMenu(BlueprintNode node, RenderContext ctx) {
  final menu = node as ActionMenuNode;
  return _ActionMenuWidget(menu: menu, ctx: ctx);
}

class _ActionMenuWidget extends StatelessWidget {
  final ActionMenuNode menu;
  final RenderContext ctx;

  const _ActionMenuWidget({required this.menu, required this.ctx});

  IconData _resolveIcon(String name) {
    return switch (name) {
      'add' || 'plus' => PhosphorIcons.plus(PhosphorIconsStyle.regular),
      'edit' || 'pencil' => PhosphorIcons.pencilSimple(PhosphorIconsStyle.regular),
      'delete' || 'trash' => PhosphorIcons.trash(PhosphorIconsStyle.regular),
      'check' => PhosphorIcons.check(PhosphorIconsStyle.regular),
      'settings' || 'gear' => PhosphorIcons.gear(PhosphorIconsStyle.regular),
      'share' => PhosphorIcons.shareFat(PhosphorIconsStyle.regular),
      'dots-three' => PhosphorIcons.dotsThree(PhosphorIconsStyle.regular),
      _ => PhosphorIcons.circle(PhosphorIconsStyle.regular),
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final triggerIcon = _resolveIcon(menu.icon);

    return PopupMenuButton<int>(
      icon: Icon(triggerIcon, color: colors.onBackground),
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.border),
      ),
      itemBuilder: (_) {
        return menu.items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final label = item['label'] as String? ?? '';
          final iconName = item['icon'] as String?;
          final iconData = iconName != null ? _resolveIcon(iconName) : null;

          return PopupMenuItem<int>(
            value: index,
            child: Row(
              children: [
                if (iconData != null) ...[
                  Icon(iconData, size: 18, color: colors.onBackground),
                  const SizedBox(width: 12),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Karla',
                    fontSize: 14,
                    color: colors.onBackground,
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
      onSelected: (index) {
        if (index < menu.items.length) {
          final action =
              menu.items[index]['action'] as Map<String, dynamic>? ?? {};
          BlueprintActionDispatcher.dispatch(action, ctx, context);
        }
      },
    );
  }
}
