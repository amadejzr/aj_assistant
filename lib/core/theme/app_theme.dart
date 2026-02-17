import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final AppColors colors;

  const AppColorsExtension({required this.colors});

  @override
  AppColorsExtension copyWith({AppColors? colors}) {
    return AppColorsExtension(colors: colors ?? this.colors);
  }

  @override
  AppColorsExtension lerp(
    covariant ThemeExtension<AppColorsExtension>? other,
    double t,
  ) {
    return this;
  }
}

abstract final class AppTheme {
  static ThemeData dark() {
    const colors = AppColorsDark();
    return _buildTheme(colors, Brightness.dark);
  }

  static ThemeData light() {
    const colors = AppColorsLight();
    return _buildTheme(colors, Brightness.light);
  }

  static ThemeData _buildTheme(AppColors colors, Brightness brightness) {
    final textTheme = AppTypography.textTheme(colors);

    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: colors.background,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: colors.accent,
        onPrimary: colors.onBackground,
        secondary: colors.accentMuted,
        onSecondary: colors.onBackground,
        error: colors.error,
        onError: colors.onBackground,
        surface: colors.surface,
        onSurface: colors.onBackground,
      ),
      textTheme: textTheme,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(
          fontFamily: 'Karla',
          fontSize: 15,
          color: colors.onBackgroundMuted.withValues(alpha: 0.5),
        ),
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.error, width: 1.5),
        ),
      ),
      extensions: [AppColorsExtension(colors: colors)],
    );
  }
}

extension AppColorsX on BuildContext {
  AppColors get colors =>
      Theme.of(this).extension<AppColorsExtension>()!.colors;
}
