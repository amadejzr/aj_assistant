import 'package:flutter/material.dart';

import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../engine/action_dispatcher.dart';
import '../../renderer/blueprint_node.dart';
import '../../renderer/render_context.dart';

/// Renders a circular icon button with an optional tooltip that dispatches a blueprint action on tap.
///
/// Blueprint JSON:
/// ```json
/// {"type": "icon_button", "icon": "edit", "action": {"type": "navigate", "screen": "edit"}, "tooltip": "Edit entry"}
/// ```
///
/// - `icon` (`String`, required): Icon name resolved to a Phosphor icon (e.g., `"add"`, `"edit"`, `"delete"`, `"settings"`, `"share"`, `"close"`, `"arrow-left"`, `"arrow-right"`).
/// - `action` (`Map<String, dynamic>`, optional): Action configuration dispatched via `BlueprintActionDispatcher` on tap.
/// - `tooltip` (`String?`, optional): Tooltip text shown on long press.
Widget buildIconButton(BlueprintNode node, RenderContext ctx) {
  final btn = node as IconButtonNode;
  return _IconButtonWidget(btn: btn, ctx: ctx);
}

class _IconButtonWidget extends StatelessWidget {
  final IconButtonNode btn;
  final RenderContext ctx;

  const _IconButtonWidget({required this.btn, required this.ctx});

  IconData _resolveIcon(String name) {
    return switch (name) {
      'add' || 'plus' => PhosphorIcons.plus(PhosphorIconsStyle.regular),
      'edit' || 'pencil' => PhosphorIcons.pencilSimple(PhosphorIconsStyle.regular),
      'delete' || 'trash' => PhosphorIcons.trash(PhosphorIconsStyle.regular),
      'check' => PhosphorIcons.check(PhosphorIconsStyle.regular),
      'check-circle' => PhosphorIcons.checkCircle(PhosphorIconsStyle.regular),
      'settings' || 'gear' => PhosphorIcons.gear(PhosphorIconsStyle.regular),
      'share' => PhosphorIcons.shareFat(PhosphorIconsStyle.regular),
      'close' || 'x' => PhosphorIcons.x(PhosphorIconsStyle.regular),
      'arrow-left' => PhosphorIcons.arrowLeft(PhosphorIconsStyle.regular),
      'arrow-right' => PhosphorIcons.arrowRight(PhosphorIconsStyle.regular),
      _ => PhosphorIcons.circle(PhosphorIconsStyle.regular),
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final iconData = _resolveIcon(btn.icon);

    final button = Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          BlueprintActionDispatcher.dispatch(
            btn.action,
            ctx,
            context,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            iconData,
            size: 24,
            color: colors.onBackground,
          ),
        ),
      ),
    );

    if (btn.tooltip != null) {
      return Tooltip(
        message: btn.tooltip!,
        child: button,
      );
    }

    return button;
  }
}
