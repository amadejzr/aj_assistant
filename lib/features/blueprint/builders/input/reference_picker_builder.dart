import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../engine/action_dispatcher.dart';
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
/// - `emptyLabel` (`String`, optional): Text shown when no entries match the query. Defaults to `"None available"`.
/// - `emptyAction` (`Map<String, dynamic>`, optional): Action dispatched when the empty-state link is tapped (e.g. navigate to a create form).
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

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final meta = _resolveFieldMeta();
    final label = meta.label;
    final isRequired = meta.required;

    final source = input.properties['source'] as String?;
    final matchingEntries = source != null
        ? (ctx.queryResults[source] ?? [])
        : <Map<String, dynamic>>[];

    final currentValue = ctx.getFormValue(input.fieldKey) as String?;

    final emptyLabel =
        input.properties['emptyLabel'] as String? ?? 'None available';
    final emptyAction =
        input.properties['emptyAction'] as Map<String, dynamic>?;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: FormField<String>(
        initialValue: currentValue,
        validator: isRequired
            ? (value) {
                if (value == null || value.isEmpty) {
                  return '$label is required';
                }
                return null;
              }
            : null,
        builder: (field) {
          return Column(
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
              if (matchingEntries.isEmpty)
                _buildEmptyState(colors, emptyLabel, emptyAction)
              else
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: matchingEntries.map((entry) {
                    final entryId = entry['id']?.toString() ?? '';
                    final displayText =
                        entry[input.displayField]?.toString() ?? entryId;
                    final isSelected = currentValue == entryId;

                    return GestureDetector(
                      onTap: () {
                        ctx.onFormValueChanged(input.fieldKey, entryId);
                        field.didChange(entryId);
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
                  }).toList(),
                ),
              if (field.hasError)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    field.errorText!,
                    style: const TextStyle(
                      fontFamily: 'Karla',
                      fontSize: 12,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(
    AppColors colors,
    String emptyLabel,
    Map<String, dynamic>? emptyAction,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          emptyLabel,
          style: TextStyle(
            fontFamily: 'Karla',
            fontSize: 14,
            color: colors.onBackgroundMuted,
          ),
        ),
        if (emptyAction != null) ...[
          const SizedBox(height: AppSpacing.xs),
          GestureDetector(
            onTap: () {
              BlueprintActionDispatcher.dispatch(emptyAction, ctx, context);
            },
            child: Text(
              emptyAction['label'] as String? ??
                  _defaultActionLabel(emptyAction),
              style: TextStyle(
                fontFamily: 'Karla',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.accent,
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _defaultActionLabel(Map<String, dynamic> action) {
    final screen = action['screen'] as String? ?? '';
    // "add_goal" → "Create Goal"
    if (screen.startsWith('add_')) {
      final noun = screen.substring(4).replaceAll('_', ' ');
      return 'Create ${noun[0].toUpperCase()}${noun.substring(1)}';
    }
    return 'Create';
  }
}
