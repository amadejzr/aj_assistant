import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../blueprint_node.dart';
import '../render_context.dart';
import '../widget_registry.dart';

Widget buildRow(BlueprintNode node, RenderContext ctx) {
  final row = node as RowNode;
  final registry = WidgetRegistry.instance;

  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (var i = 0; i < row.children.length; i++) ...[
        Expanded(child: registry.build(row.children[i], ctx)),
        if (i < row.children.length - 1) const SizedBox(width: AppSpacing.md),
      ],
    ],
  );
}
