import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Resolves a module's icon name string to a Phosphor [IconData].
IconData resolveModuleIcon(String iconName) {
  return switch (iconName) {
    'barbell' => PhosphorIcons.barbell(PhosphorIconsStyle.duotone),
    'wallet' => PhosphorIcons.wallet(PhosphorIconsStyle.duotone),
    'heart' => PhosphorIcons.heartbeat(PhosphorIconsStyle.duotone),
    'book' => PhosphorIcons.book(PhosphorIconsStyle.duotone),
    'chart' => PhosphorIcons.chartBar(PhosphorIconsStyle.duotone),
    'calendar' => PhosphorIcons.calendar(PhosphorIconsStyle.duotone),
    'list' => PhosphorIcons.listChecks(PhosphorIconsStyle.duotone),
    'mountains' => PhosphorIcons.mountains(PhosphorIconsStyle.duotone),
    _ => PhosphorIcons.cube(PhosphorIconsStyle.duotone),
  };
}

/// Parses a hex color string (e.g. `#D94E33`) into a [Color].
Color parseModuleColor(String hex) {
  final hexCode = hex.replaceAll('#', '');
  return Color(int.parse('FF$hexCode', radix: 16));
}
