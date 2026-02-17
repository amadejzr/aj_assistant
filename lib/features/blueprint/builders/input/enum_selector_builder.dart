import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../renderer/blueprint_node.dart';
import '../../renderer/render_context.dart';

/// Renders a chip-based selector for single or multiple enum values derived from the schema field options.
///
/// Blueprint JSON:
/// ```json
/// {"type": "enum_selector", "fieldKey": "category", "multiSelect": false}
/// ```
///
/// - `fieldKey` (`String`, required): Schema field key this selector is bound to. Options are derived from the field definition.
/// - `multiSelect` (`bool`, optional): Whether multiple options can be selected simultaneously. Defaults to `false`.
Widget buildEnumSelector(BlueprintNode node, RenderContext ctx) {
  final input = node as EnumSelectorNode;
  return _EnumSelectorWidget(input: input, ctx: ctx);
}

class _EnumSelectorWidget extends StatelessWidget {
  final EnumSelectorNode input;
  final RenderContext ctx;

  const _EnumSelectorWidget({required this.input, required this.ctx});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final field = ctx.getFieldDefinition(input.fieldKey);
    final label = field?.label ?? input.fieldKey;
    final options = field?.options ?? [];
    final currentValue = ctx.getFormValue(input.fieldKey);

    // For multi-select, currentValue is a List<String>
    final selectedValues = input.multiSelect
        ? List<String>.from(currentValue as List? ?? [])
        : <String>[];
    final singleValue = !input.multiSelect ? currentValue as String? : null;

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
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: options.map((option) {
              final isSelected = input.multiSelect
                  ? selectedValues.contains(option)
                  : singleValue == option;

              return GestureDetector(
                onTap: () {
                  if (input.multiSelect) {
                    final updated = List<String>.from(selectedValues);
                    if (updated.contains(option)) {
                      updated.remove(option);
                    } else {
                      updated.add(option);
                    }
                    ctx.onFormValueChanged(input.fieldKey, updated);
                  } else {
                    ctx.onFormValueChanged(input.fieldKey, option);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accent : colors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? colors.accent
                          : colors.border,
                    ),
                  ),
                  child: Text(
                    option,
                    style: TextStyle(
                      fontFamily: 'Karla',
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected
                          ? Colors.white
                          : colors.onBackground,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
