import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../renderer/blueprint_node.dart';
import '../../renderer/render_context.dart';

/// Renders a labeled boolean toggle switch bound to a schema field.
///
/// Blueprint JSON:
/// ```json
/// {"type": "toggle", "fieldKey": "completed"}
/// ```
///
/// - `fieldKey` (`String`, required): Schema field key this toggle is bound to. Stores a `bool` value.
Widget buildToggle(BlueprintNode node, RenderContext ctx) {
  final input = node as ToggleNode;
  return _ToggleWidget(input: input, ctx: ctx);
}

class _ToggleWidget extends StatelessWidget {
  final ToggleNode input;
  final RenderContext ctx;

  const _ToggleWidget({required this.input, required this.ctx});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final meta = ctx.resolveFieldMeta(input.fieldKey, input.properties);
    final label = meta.label;
    final raw = ctx.getFormValue(input.fieldKey);
    final currentValue = raw is bool ? raw : (raw == 1 || raw == true);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Karla',
              fontSize: 15,
              color: colors.onBackground,
            ),
          ),
          Switch.adaptive(
            value: currentValue,
            activeTrackColor: colors.accent,
            activeThumbColor: Colors.white,
            onChanged: (value) {
              ctx.onFormValueChanged(input.fieldKey, value);
            },
          ),
        ],
      ),
    );
  }
}
