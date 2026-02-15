import 'package:flutter/material.dart';

abstract class AppColors {
  Color get background;
  Color get surface;
  Color get surfaceVariant;
  Color get onBackground;
  Color get onBackgroundMuted;
  Color get accent;
  Color get accentMuted;
  Color get border;
  Color get error;
  Color get success;
  Color get gradientStart;
  Color get gradientEnd;
}

class AppColorsDark implements AppColors {
  const AppColorsDark();

  @override
  Color get background => const Color(0xFF1A1A1E);
  @override
  Color get surface => const Color(0xFF242428);
  @override
  Color get surfaceVariant => const Color(0xFF2E2E33);
  @override
  Color get onBackground => const Color(0xFFF2EDE8);
  @override
  Color get onBackgroundMuted => const Color(0xFF8A857E);
  @override
  Color get accent => const Color(0xFFE8A84C);
  @override
  Color get accentMuted => const Color(0x26E8A84C);
  @override
  Color get border => const Color(0x14FFFFFF);
  @override
  Color get error => const Color(0xFFE85C5C);
  @override
  Color get success => const Color(0xFF5CE88A);
  @override
  Color get gradientStart => const Color(0xFF1E1E22);
  @override
  Color get gradientEnd => const Color(0xFF1A1A1E);
}

class AppColorsLight implements AppColors {
  const AppColorsLight();

  @override
  Color get background => const Color(0xFFFAF7F2);
  @override
  Color get surface => const Color(0xFFFFFFFF);
  @override
  Color get surfaceVariant => const Color(0xFFF0EBE3);
  @override
  Color get onBackground => const Color(0xFF2C2520);
  @override
  Color get onBackgroundMuted => const Color(0xFF9C958C);
  @override
  Color get accent => const Color(0xFFD4922E);
  @override
  Color get accentMuted => const Color(0x1AD4922E);
  @override
  Color get border => const Color(0x14000000);
  @override
  Color get error => const Color(0xFFE85C5C);
  @override
  Color get success => const Color(0xFF5CE88A);
  @override
  Color get gradientStart => const Color(0xFFFAF7F2);
  @override
  Color get gradientEnd => const Color(0xFFF5F0E8);
}
