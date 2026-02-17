import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../renderer/blueprint_node.dart';
import '../../renderer/render_context.dart';

Widget buildDividerWidget(BlueprintNode node, RenderContext ctx) {
  return _DividerWidget();
}

class _DividerWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Divider(color: colors.border, height: 1),
    );
  }
}
