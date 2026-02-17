import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../engine/action_dispatcher.dart';
import '../../renderer/blueprint_node.dart';
import '../../renderer/render_context.dart';

/// Renders a floating action button with a Phosphor icon that dispatches a blueprint action on tap.
///
/// Blueprint JSON:
/// ```json
/// {"type": "fab", "icon": "add", "action": {"type": "navigate", "screen": "add_entry"}}
/// ```
///
/// - `icon` (`String?`, optional): Icon name resolved to a Phosphor icon (e.g., `"add"`, `"edit"`, `"check"`). Defaults to `"add"`.
/// - `action` (`Map<String, dynamic>`, optional): Action configuration dispatched via `BlueprintActionDispatcher` on tap.
Widget buildFab(BlueprintNode node, RenderContext ctx) {
  final fab = node as FabNode;
  return _FabWidget(fab: fab, ctx: ctx);
}

class _FabWidget extends StatelessWidget {
  final FabNode fab;
  final RenderContext ctx;

  const _FabWidget({required this.fab, required this.ctx});

  IconData _resolveIcon(String? iconName) {
    return switch (iconName) {
      'add' => PhosphorIcons.plus(PhosphorIconsStyle.bold),
      'edit' => PhosphorIcons.pencilSimple(PhosphorIconsStyle.bold),
      'check' => PhosphorIcons.check(PhosphorIconsStyle.bold),
      _ => PhosphorIcons.plus(PhosphorIconsStyle.bold),
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return FloatingActionButton(
      backgroundColor: colors.accent,
      foregroundColor: Colors.white,
      onPressed: () => BlueprintActionDispatcher.dispatch(fab.action, ctx, context),
      child: Icon(_resolveIcon(fab.icon)),
    );
  }
}
