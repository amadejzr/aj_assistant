import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppTypography {
  static TextTheme textTheme(AppColors colors) {
    final onBg = colors.onBackground;
    final muted = colors.onBackgroundMuted;

    return TextTheme(
      displayLarge: GoogleFonts.bricolageGrotesque(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: onBg,
        height: 1.2,
      ),
      headlineMedium: GoogleFonts.bricolageGrotesque(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: onBg,
        height: 1.3,
      ),
      titleMedium: GoogleFonts.dmSans(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: onBg,
        height: 1.4,
      ),
      bodyLarge: GoogleFonts.dmSans(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: onBg,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.dmSans(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: muted,
        height: 1.5,
      ),
      labelSmall: GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: muted,
        height: 1.4,
      ),
      labelLarge: GoogleFonts.dmMono(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: onBg,
        height: 1.5,
      ),
    );
  }
}
