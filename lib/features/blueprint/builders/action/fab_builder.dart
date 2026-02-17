import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../engine/action_dispatcher.dart';
import '../../renderer/blueprint_node.dart';
import '../../renderer/render_context.dart';

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
