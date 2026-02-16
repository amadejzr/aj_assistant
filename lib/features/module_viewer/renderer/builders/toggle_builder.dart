import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../blueprint_node.dart';
import '../render_context.dart';

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
    final field = ctx.getFieldDefinition(input.fieldKey);
    final label = field?.label ?? input.fieldKey;
    final currentValue = ctx.getFormValue(input.fieldKey) as bool? ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.karla(
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
