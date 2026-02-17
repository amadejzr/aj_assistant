import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../renderer/blueprint_node.dart';
import '../../renderer/render_context.dart';
import '../../renderer/widget_registry.dart';

/// Renders a vertically scrollable column of child widgets with standard padding.
///
/// Blueprint JSON:
/// ```json
/// {"type": "scroll_column", "children": [{"type": "text_display", "text": "Hello"}]}
/// ```
///
/// - `children` (`List<BlueprintNode>`, optional): Child widgets rendered vertically with spacing between them.
Widget buildScrollColumn(BlueprintNode node, RenderContext ctx) {
  final col = node as ScrollColumnNode;
  final registry = WidgetRegistry.instance;

  return SingleChildScrollView(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.screenPadding,
      vertical: AppSpacing.md,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final child in col.children) ...[
          registry.build(child, ctx),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    ),
  );
}
