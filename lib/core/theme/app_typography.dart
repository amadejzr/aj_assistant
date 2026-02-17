import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTypography {
  static TextTheme textTheme(AppColors colors) {
    final onBg = colors.onBackground;
    final muted = colors.onBackgroundMuted;

    return TextTheme(
      // Headlines — Cormorant Garamond: calligraphic serif, ink-like quality
      displayLarge: TextStyle(
        fontFamily: 'CormorantGaramond',
        fontSize: 34,
        fontWeight: FontWeight.w600,
        color: onBg,
        height: 1.15,
        letterSpacing: -0.3,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'CormorantGaramond',
        fontSize: 26,
        fontWeight: FontWeight.w600,
        color: onBg,
        height: 1.25,
      ),
      // Body — Karla: warm geometric sans, clean and readable
      titleMedium: TextStyle(
        fontFamily: 'Karla',
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: onBg,
        height: 1.4,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Karla',
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: onBg,
        height: 1.55,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Karla',
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: muted,
        height: 1.55,
      ),
      labelSmall: TextStyle(
        fontFamily: 'Karla',
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: muted,
        height: 1.4,
      ),
      // Tabular — Karla with tabular figures (replaces IBM Plex Mono)
      labelLarge: TextStyle(
        fontFamily: 'Karla',
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: onBg,
        height: 1.5,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    );
  }
}
