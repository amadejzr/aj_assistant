import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../renderer/blueprint_node.dart';
import '../../renderer/render_context.dart';

/// Renders a numeric form field with decimal support and min/max validation from schema constraints.
///
/// Blueprint JSON:
/// ```json
/// {"type": "number_input", "fieldKey": "duration"}
/// ```
///
/// - `fieldKey` (`String`, required): Schema field key this input is bound to. Label, required flag, and min/max constraints are derived from the field definition.
Widget buildNumberInput(BlueprintNode node, RenderContext ctx) {
  final input = node as NumberInputNode;
  return _NumberInputWidget(input: input, ctx: ctx);
}

class _NumberInputWidget extends StatelessWidget {
  final NumberInputNode input;
  final RenderContext ctx;

  const _NumberInputWidget({required this.input, required this.ctx});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final field = ctx.getFieldDefinition(input.fieldKey);
    final label = input.properties['label'] as String? ?? field?.label ?? input.fieldKey;
    final isRequired = field?.required ?? false;
    final min = field?.constraints['min'] as num?;
    final max = field?.constraints['max'] as num?;
    final currentValue = ctx.getFormValue(input.fieldKey);
    final initialText = currentValue != null ? '$currentValue' : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextFormField(
        initialValue: initialText,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
        ],
        style: TextStyle(
          fontFamily: 'Karla',
          fontSize: 15,
          color: colors.onBackground,
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
          if (isRequired && (v == null || v.isEmpty)) {
            return '$label is required';
          }
          if (v != null && v.isNotEmpty) {
            final n = num.tryParse(v);
            if (n == null) return 'Enter a valid number';
            if (min != null && n < min) return 'Minimum is $min';
            if (max != null && n > max) return 'Maximum is $max';
          }
          return null;
        },
        onChanged: (value) {
          final parsed = num.tryParse(value);
          ctx.onFormValueChanged(input.fieldKey, parsed);
        },
      ),
    );
  }
}
