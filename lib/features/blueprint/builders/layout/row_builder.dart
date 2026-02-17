import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../renderer/blueprint_node.dart';
import '../../renderer/render_context.dart';
import '../../renderer/widget_registry.dart';

/// Renders children in a horizontal row with equal expansion and spacing.
///
/// Blueprint JSON:
/// ```json
/// {"type": "row", "children": [{"type": "stat_card", "label": "A", "stat": "count"}, {"type": "stat_card", "label": "B", "stat": "count"}]}
/// ```
///
/// - `children` (`List<BlueprintNode>`, optional): Child widgets rendered side-by-side, each wrapped in `Expanded`.
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
