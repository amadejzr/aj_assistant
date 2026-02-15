import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppTypography {
  static TextTheme textTheme(AppColors colors) {
    final onBg = colors.onBackground;
    final muted = colors.onBackgroundMuted;

    return TextTheme(
      // Headlines — Cormorant Garamond: calligraphic serif, ink-like quality
      displayLarge: GoogleFonts.cormorantGaramond(
        fontSize: 34,
        fontWeight: FontWeight.w600,
        color: onBg,
        height: 1.15,
        letterSpacing: -0.3,
      ),
      headlineMedium: GoogleFonts.cormorantGaramond(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        color: onBg,
        height: 1.25,
      ),
      // Body — Karla: warm geometric sans, clean and readable
      titleMedium: GoogleFonts.karla(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: onBg,
        height: 1.4,
      ),
      bodyLarge: GoogleFonts.karla(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: onBg,
        height: 1.55,
      ),
      bodyMedium: GoogleFonts.karla(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: muted,
        height: 1.55,
      ),
      labelSmall: GoogleFonts.karla(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: muted,
        height: 1.4,
      ),
      // Mono — IBM Plex Mono: slightly warmer than most monospace
      labelLarge: GoogleFonts.ibmPlexMono(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: onBg,
        height: 1.5,
      ),
    );
  }
}
