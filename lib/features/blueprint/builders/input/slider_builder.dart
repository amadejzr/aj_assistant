import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../renderer/blueprint_node.dart';
import '../../renderer/render_context.dart';

Widget buildSliderInput(BlueprintNode node, RenderContext ctx) {
  final input = node as SliderNode;
  return _SliderWidget(input: input, ctx: ctx);
}

class _SliderWidget extends StatelessWidget {
  final SliderNode input;
  final RenderContext ctx;

  const _SliderWidget({required this.input, required this.ctx});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final field = ctx.getFieldDefinition(input.fieldKey);
    final label = field?.label ?? input.fieldKey;
    final min = (field?.constraints['min'] as num?)?.toDouble() ?? 0.0;
    final max = (field?.constraints['max'] as num?)?.toDouble() ?? 100.0;
    final divisions = (field?.constraints['divisions'] as num?)?.toInt();
    final currentValue =
        (ctx.getFormValue(input.fieldKey) as num?)?.toDouble() ?? min;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Karla',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colors.onBackgroundMuted,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                currentValue.toStringAsFixed(
                  currentValue == currentValue.roundToDouble() ? 0 : 1,
                ),
                style: TextStyle(
                  fontFamily: 'Karla',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colors.onBackground,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: colors.accent,
              inactiveTrackColor: colors.border,
              thumbColor: colors.accent,
              overlayColor: colors.accent.withValues(alpha: 0.15),
            ),
            child: Slider(
              value: currentValue.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: (value) {
                ctx.onFormValueChanged(input.fieldKey, value);
              },
            ),
          ),
        ],
      ),
    );
  }
}
