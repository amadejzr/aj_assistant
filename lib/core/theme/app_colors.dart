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

/// Dark theme — Sumi ink stone aesthetic.
/// Warm blacks like ground ink, paper-white text, vermillion accent.
class AppColorsDark implements AppColors {
  const AppColorsDark();

  @override
  Color get background => const Color(0xFF1C1917); // warm charcoal, ink stone
  @override
  Color get surface => const Color(0xFF292524); // slightly lifted
  @override
  Color get surfaceVariant => const Color(0xFF3B3633);
  @override
  Color get onBackground => const Color(0xFFF5F0E8); // warm paper white
  @override
  Color get onBackgroundMuted => const Color(0xFF9C9489); // diluted ink
  @override
  Color get accent => const Color(0xFFD94E33); // vermillion (hanko stamp)
  @override
  Color get accentMuted => const Color(0x22D94E33);
  @override
  Color get border => const Color(0x18F5F0E8);
  @override
  Color get error => const Color(0xFFCC3D3D);
  @override
  Color get success => const Color(0xFF6B9E6B);
  @override
  Color get gradientStart => const Color(0xFF201D1A);
  @override
  Color get gradientEnd => const Color(0xFF1C1917);
}

/// Light theme — Washi paper aesthetic.
/// Aged cream background, sumi ink text, vermillion accent.
class AppColorsLight implements AppColors {
  const AppColorsLight();

  @override
  Color get background => const Color(0xFFF6F1E9); // aged washi paper
  @override
  Color get surface => const Color(0xFFFFFCF7); // slightly brighter paper
  @override
  Color get surfaceVariant => const Color(0xFFEDE7DC);
  @override
  Color get onBackground => const Color(0xFF1C1917); // sumi ink
  @override
  Color get onBackgroundMuted => const Color(0xFF8A847A); // diluted ink
  @override
  Color get accent => const Color(0xFFC44230); // vermillion, slightly deeper
  @override
  Color get accentMuted => const Color(0x18C44230);
  @override
  Color get border => const Color(0x12000000);
  @override
  Color get error => const Color(0xFFB83030);
  @override
  Color get success => const Color(0xFF4E8A4E);
  @override
  Color get gradientStart => const Color(0xFFF6F1E9);
  @override
  Color get gradientEnd => const Color(0xFFF0EADE);
}
