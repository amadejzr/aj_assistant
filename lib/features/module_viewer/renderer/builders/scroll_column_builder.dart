import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../blueprint_node.dart';
import '../render_context.dart';
import '../widget_registry.dart';

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
