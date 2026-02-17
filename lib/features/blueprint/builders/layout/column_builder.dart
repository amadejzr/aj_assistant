import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../renderer/blueprint_node.dart';
import '../../renderer/render_context.dart';
import '../../renderer/widget_registry.dart';

/// Renders children in a vertical column with stretch alignment and spacing.
///
/// Blueprint JSON:
/// ```json
/// {"type": "column", "children": [{"type": "text_display", "text": "Line 1"}, {"type": "text_display", "text": "Line 2"}]}
/// ```
///
/// - `children` (`List<BlueprintNode>`, optional): Child widgets rendered vertically with small spacing between them.
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
