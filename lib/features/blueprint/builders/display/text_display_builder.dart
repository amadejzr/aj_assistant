import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../renderer/blueprint_node.dart';
import '../../renderer/reference_resolver.dart';
import '../../renderer/render_context.dart';

/// Renders a styled text widget with mustache-template interpolation from screen params and form values.
///
/// Blueprint JSON:
/// ```json
/// {"type": "text_display", "text": "Hello, {{name}}!", "style": "headline"}
/// ```
///
/// - `text` (`String`, required): Text content with optional `{{key}}` template placeholders.
/// - `style` (`String?`, optional): Text style variant. One of `"headline"`, `"title"`, `"caption"`, or default body style.
Widget buildTextDisplay(BlueprintNode node, RenderContext ctx) {
  final display = node as TextDisplayNode;
  return _TextDisplayWidget(display: display, ctx: ctx);
}

class _TextDisplayWidget extends StatelessWidget {
  final TextDisplayNode display;
  final RenderContext ctx;

  const _TextDisplayWidget({required this.display, required this.ctx});

  String _formatValue(dynamic value) {
    if (value == null) return '';
    final str = value.toString();

    final date = DateTime.tryParse(str);
    if (date != null) {
      if (date.hour == 0 && date.minute == 0 && date.second == 0) {
        return DateFormat.yMMMd().format(date);
      }
      return DateFormat.yMMMd().add_jm().format(date);
    }

    final timeMatch = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(str);
    if (timeMatch != null) {
      final hour = int.parse(timeMatch.group(1)!);
      final minute = int.parse(timeMatch.group(2)!);
      final now = DateTime.now();
      final dt = DateTime(now.year, now.month, now.day, hour, minute);
      return DateFormat.jm().format(dt);
    }

    return str;
  }

  String _interpolate(String template) {
    final data = {...ctx.screenParams, ...ctx.formValues};
    final resolver = ReferenceResolver(
      module: ctx.module,
      allEntries: const [],
    );
    final schemaKey =
        ctx.screenParams['_schemaKey'] as String?;

    return template.replaceAllMapped(
      RegExp(r'\{\{([\w.]+)\}\}'),
      (match) {
        final expr = match.group(1)!;
        final dotIndex = expr.indexOf('.');
        if (dotIndex != -1) {
          final fieldKey = expr.substring(0, dotIndex);
          final subField = expr.substring(dotIndex + 1);
          final value = data[fieldKey];
          final resolved = resolver.resolveField(
            fieldKey,
            subField,
            value,
            schemaKey: schemaKey,
          );
          return resolved.isNotEmpty ? resolved : _formatValue(value);
        }
        final value = data[expr];
        final resolved = resolver.resolve(expr, value, schemaKey: schemaKey);
        if (resolved == (value?.toString() ?? '')) {
          return _formatValue(value);
        }
        return resolved;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = _interpolate(display.text);

    TextStyle style;
    switch (display.style) {
      case 'headline':
        style = TextStyle(
          fontFamily: 'CormorantGaramond',
          fontSize: 26,
          fontWeight: FontWeight.w600,
          color: colors.onBackground,
        );
      case 'title':
        style = TextStyle(
          fontFamily: 'Karla',
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: colors.onBackground,
        );
      case 'caption':
        style = TextStyle(
          fontFamily: 'Karla',
          fontSize: 12,
          color: colors.onBackgroundMuted,
        );
      default:
        style = TextStyle(
          fontFamily: 'Karla',
          fontSize: 15,
          color: colors.onBackground,
        );
    }

    return Text(text, style: style);
  }
}
