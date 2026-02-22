import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../renderer/blueprint_node.dart';
import '../../renderer/render_context.dart';

/// Renders a star-based rating input with tap-to-select and tap-to-clear behavior.
///
/// Blueprint JSON:
/// ```json
/// {"type": "rating_input", "fieldKey": "rating"}
/// ```
///
/// - `fieldKey` (`String`, required): Schema field key this rating is bound to. Max stars are read from the field's `constraints.max` (defaults to 5). Stores an `int` value.
Widget buildRatingInput(BlueprintNode node, RenderContext ctx) {
  final input = node as RatingInputNode;
  return _RatingInputWidget(input: input, ctx: ctx);
}

class _RatingInputWidget extends StatelessWidget {
  final RatingInputNode input;
  final RenderContext ctx;

  const _RatingInputWidget({required this.input, required this.ctx});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final meta = ctx.resolveFieldMeta(input.fieldKey, input.properties);
    final label = meta.label;
    final maxStars = meta.maxRating ?? 5;
    final currentValue = (ctx.getFormValue(input.fieldKey) as num?)?.toInt() ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(maxStars, (index) {
              final starIndex = index + 1;
              final isFilled = starIndex <= currentValue;

              return GestureDetector(
                onTap: () {
                  final newValue = starIndex == currentValue ? 0 : starIndex;
                  ctx.onFormValueChanged(input.fieldKey, newValue);
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    isFilled
                        ? PhosphorIcons.star(PhosphorIconsStyle.fill)
                        : PhosphorIcons.star(PhosphorIconsStyle.regular),
                    size: 32,
                    color: isFilled
                        ? colors.accent
                        : colors.onBackgroundMuted,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
