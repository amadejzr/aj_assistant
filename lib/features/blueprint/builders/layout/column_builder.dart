import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../renderer/blueprint_node.dart';
import '../../renderer/render_context.dart';
import '../../renderer/widget_registry.dart';

Widget buildColumnLayout(BlueprintNode node, RenderContext ctx) {
  final col = node as ColumnNode;
  final registry = WidgetRegistry.instance;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < col.children.length; i++) ...[
        registry.build(col.children[i], ctx),
        if (i < col.children.length - 1) const SizedBox(height: AppSpacing.sm),
      ],
    ],
  );
}
