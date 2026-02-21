import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../renderer/blueprint_node.dart';
import '../../renderer/field_meta.dart';
import '../../renderer/render_context.dart';

/// Renders a chip-based picker for selecting a reference entry from another schema.
///
/// Blueprint JSON:
/// ```json
/// {"type": "reference_picker", "fieldKey": "exerciseId", "schemaKey": "exercises", "displayField": "name"}
/// ```
///
/// - `fieldKey` (`String`, required): Schema field key this picker is bound to. Stores the selected entry's ID.
/// - `schemaKey` (`String`, required): The key of the target schema whose entries are listed as options.
/// - `displayField` (`String`, optional): Field key from the referenced entries used as the display label. Defaults to `"name"`.
Widget buildReferencePicker(BlueprintNode node, RenderContext ctx) {
  final input = node as ReferencePickerNode;
  return _ReferencePickerWidget(input: input, ctx: ctx);
}

class _ReferencePickerWidget extends StatefulWidget {
  final ReferencePickerNode input;
  final RenderContext ctx;

  const _ReferencePickerWidget({required this.input, required this.ctx});

  @override
  State<_ReferencePickerWidget> createState() => _ReferencePickerWidgetState();
}

class _ReferencePickerWidgetState extends State<_ReferencePickerWidget> {
  ReferencePickerNode get input => widget.input;
  RenderContext get ctx => widget.ctx;

  FieldMeta _resolveFieldMeta() {
    return ctx.resolveFieldMeta(input.fieldKey, input.properties);
  }

  String _resolveSchemaKey(FieldMeta meta) {
    if (input.schemaKey.isNotEmpty) return input.schemaKey;
    return meta.targetSchema ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final meta = _resolveFieldMeta();
    final label = meta.label;
    final schemaKey = _resolveSchemaKey(meta);

    final matchingEntries = ctx.allEntries
        .where((e) => e.schemaKey == schemaKey)
        .toList();

    final currentValue = ctx.getFormValue(input.fieldKey) as String?;

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
            children: [
              ...matchingEntries.map((entry) {
                final displayText =
                    entry.data[input.displayField]?.toString() ?? entry.id;
                final isSelected = currentValue == entry.id;

                return GestureDetector(
                  onTap: () {
                    ctx.onFormValueChanged(input.fieldKey, entry.id);
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
                        color: isSelected ? colors.accent : colors.border,
                      ),
                    ),
                    child: Text(
                      displayText,
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
              }),
            ],
          ),
        ],
      ),
    );
  }
}
