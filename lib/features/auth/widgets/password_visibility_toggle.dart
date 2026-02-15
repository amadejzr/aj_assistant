import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/app_theme.dart';

class PasswordVisibilityToggle extends StatelessWidget {
  final bool obscured;
  final VoidCallback onToggle;

  const PasswordVisibilityToggle({
    super.key,
    required this.obscured,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return IconButton(
      icon: Icon(
        obscured
            ? PhosphorIcons.eyeSlash(PhosphorIconsStyle.light)
            : PhosphorIcons.eye(PhosphorIconsStyle.light),
        color: colors.onBackgroundMuted,
        size: 20,
      ),
      onPressed: onToggle,
    );
  }
}
