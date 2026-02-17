import 'package:intl/intl.dart';

import '../renderer/render_context.dart';

/// Resolves `defaultValue` tokens in form field blueprints.
///
/// Supported tokens:
///   `{{today}}` — today's date as ISO 8601 string
///   `{{now}}` — current datetime as ISO 8601 string
///   `{{entry.fieldName}}` — value from the entry being edited
///   `{{param.key}}` — value from screen params
///   `{{settings.key}}` — value from module settings
///
/// If the defaultValue is not a token string, it is returned as-is
/// (supports literal defaults like numbers, booleans, plain strings).
class DefaultValueResolver {
  const DefaultValueResolver._();

  /// Resolves a defaultValue against the current render context.
  ///
  /// Returns null if the token cannot be resolved.
  static dynamic resolve(dynamic defaultValue, RenderContext ctx) {
    if (defaultValue == null) return null;

    if (defaultValue is! String) return defaultValue;

    final token = defaultValue.trim();

    // Check for {{...}} token pattern
    if (!token.startsWith('{{') || !token.endsWith('}}')) {
      // Plain string value — return as-is
      return defaultValue;
    }

    final inner = token.substring(2, token.length - 2).trim();

    // Built-in tokens
    switch (inner) {
      case 'today':
        return DateFormat('yyyy-MM-dd').format(DateTime.now());
      case 'now':
        return DateTime.now().toIso8601String();
    }

    // entry.fieldName — read from screen params (forwarded entry data)
    if (inner.startsWith('entry.')) {
      final fieldName = inner.substring(6);
      // Entry data is forwarded as screen params (non-meta keys)
      return ctx.screenParams[fieldName];
    }

    // param.key — read from screen params
    if (inner.startsWith('param.')) {
      final key = inner.substring(6);
      return ctx.screenParams[key];
    }

    // settings.key — read from module settings
    if (inner.startsWith('settings.')) {
      final key = inner.substring(9);
      return ctx.module.settings[key];
    }

    return null;
  }
}
