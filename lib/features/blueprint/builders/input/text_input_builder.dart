import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../engine/form_validator.dart';
import '../../renderer/blueprint_node.dart';
import '../../renderer/render_context.dart';

/// Renders a text form field bound to a schema field, with optional multiline support.
///
/// Blueprint JSON:
/// ```json
/// {"type": "text_input", "fieldKey": "name", "multiline": false}
/// ```
///
/// - `fieldKey` (`String`, required): Schema field key this input is bound to. Label and validation are derived from the field definition.
/// - `multiline` (`bool`, optional): Whether to render a multiline text area (4 lines) instead of a single line. Defaults to `false`.
/// - `readOnly` (`bool`, optional): Whether the field is read-only. Defaults to `false`.
/// - `defaultValue` (`dynamic`, optional): Default value or token (e.g., `"{{today}}"`) resolved by FormBody on init.
/// - `validation` (`Map`, optional): Validation rules — `required`, `minLength`, `maxLength`, `pattern`, `message`.
Widget buildTextInput(BlueprintNode node, RenderContext ctx) {
  final input = node as TextInputNode;
  return _TextInputWidget(input: input, ctx: ctx);
}

class _TextInputWidget extends StatelessWidget {
  final TextInputNode input;
  final RenderContext ctx;

  const _TextInputWidget({required this.input, required this.ctx});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final field = ctx.getFieldDefinition(input.fieldKey);
    final label = field?.label ?? input.fieldKey;
    final isRequired = field?.required ?? false;
    final maxLength = field?.constraints['maxLength'] as int?;
    final readOnly = input.properties['readOnly'] as bool? ?? false;
    final validation = input.properties['validation'] as Map<String, dynamic>?;
    final currentValue = ctx.getFormValue(input.fieldKey) as String? ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextFormField(
        initialValue: currentValue,
        readOnly: readOnly,
        maxLines: input.multiline ? 4 : 1,
        maxLength: maxLength,
        style: TextStyle(
          fontFamily: 'Karla',
          fontSize: 15,
          color: readOnly ? colors.onBackgroundMuted : colors.onBackground,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontFamily: 'Karla',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: colors.onBackgroundMuted,
            letterSpacing: 0.8,
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: colors.border),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: colors.accent, width: 2),
          ),
        ),
        validator: (v) {
          // Blueprint validation rules take precedence
          if (validation != null) {
            return FormValidator.validate(
              value: v,
              validation: validation,
              label: label,
            );
          }
          // Fall back to schema required check
          if (isRequired && (v == null || v.isEmpty)) {
            return '$label is required';
          }
          return null;
        },
        onChanged: readOnly
            ? null
            : (value) => ctx.onFormValueChanged(input.fieldKey, value),
      ),
    );
  }
}
