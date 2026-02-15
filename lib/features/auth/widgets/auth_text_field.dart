import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';

enum AuthTextFieldStyle { login, signup }

class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final AuthTextFieldStyle style;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.style,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isLogin = style == AuthTextFieldStyle.login;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isLogin ? label.toUpperCase() : label,
          style: isLogin
              ? GoogleFonts.karla(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colors.onBackgroundMuted,
                  letterSpacing: 1.2,
                )
              : GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colors.onBackgroundMuted,
                ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          cursorColor: colors.accent,
          style: isLogin
              ? GoogleFonts.karla(
                  fontSize: 15,
                  color: colors.onBackground,
                )
              : GoogleFonts.dmSans(
                  fontSize: 15,
                  color: colors.onBackground,
                ),
          decoration: _buildDecoration(colors),
        ),
      ],
    );
  }

  InputDecoration _buildDecoration(AppColors colors) {
    final isLogin = style == AuthTextFieldStyle.login;
    const radius = 10.0;

    return InputDecoration(
      hintText: hint,
      hintStyle: isLogin
          ? GoogleFonts.karla(
              fontSize: 15,
              color: colors.onBackgroundMuted.withValues(alpha: 0.45),
            )
          : GoogleFonts.dmSans(
              fontSize: 15,
              color: colors.onBackgroundMuted.withValues(alpha: 0.5),
            ),
      filled: true,
      fillColor: colors.surface,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(color: colors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(color: colors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(color: colors.accent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(color: colors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(color: colors.error, width: 1.5),
      ),
    );
  }
}
