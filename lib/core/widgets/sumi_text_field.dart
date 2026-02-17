import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

/// A labeled text field that follows the sumi ink aesthetic.
///
/// Renders an external label above a [TextFormField] that inherits its styling
/// from the app's [InputDecorationTheme]. Only overrides specific properties
/// like [hintText], [suffixIcon], and [prefixText].
class SumiTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final String? initialValue;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int? maxLines;
  final bool readOnly;
  final Widget? suffixIcon;
  final String? prefixText;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final List<TextInputFormatter>? inputFormatters;

  const SumiTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.initialValue,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.readOnly = false,
    this.suffixIcon,
    this.prefixText,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: TextStyle(
              fontFamily: 'Karla',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: colors.onBackgroundMuted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: maxLines,
          readOnly: readOnly,
          inputFormatters: inputFormatters,
          style: TextStyle(
            fontFamily: 'Karla',
            fontSize: 15,
            color: readOnly ? colors.onBackgroundMuted : colors.onBackground,
          ),
          cursorColor: colors.accent,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffixIcon,
            prefixText: prefixText,
          ),
          validator: validator,
          onChanged: onChanged,
          onFieldSubmitted: onFieldSubmitted,
        ),
      ],
    );
  }
}
