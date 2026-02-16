import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../blueprint_node.dart';
import '../render_context.dart';

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
    final currentValue = ctx.getFormValue(input.fieldKey) as String? ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextFormField(
        initialValue: currentValue,
        maxLines: input.multiline ? 4 : 1,
        maxLength: maxLength,
        style: GoogleFonts.karla(
          fontSize: 15,
          color: colors.onBackground,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.karla(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: colors.onBackgroundMuted,
            letterSpacing: 0.8,
          ),
          filled: true,
          fillColor: colors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: colors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: colors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: colors.accent, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 14,
          ),
        ),
        validator: isRequired
            ? (v) => (v == null || v.isEmpty) ? '$label is required' : null
            : null,
        onChanged: (value) => ctx.onFormValueChanged(input.fieldKey, value),
      ),
    );
  }
}
