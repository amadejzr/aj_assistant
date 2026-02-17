import 'package:flutter/material.dart';

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
              ? TextStyle(
                  fontFamily: 'Karla',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colors.onBackgroundMuted,
                  letterSpacing: 1.2,
                )
              : TextStyle(
                  fontFamily: 'Karla',
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
          style: TextStyle(
            fontFamily: 'Karla',
            fontSize: 15,
            color: colors.onBackground,
          ),
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}
