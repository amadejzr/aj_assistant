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
      extensions: [AppColorsExtension(colors: colors)],
    );
  }
}

extension AppColorsX on BuildContext {
  AppColors get colors =>
      Theme.of(this).extension<AppColorsExtension>()!.colors;
}
