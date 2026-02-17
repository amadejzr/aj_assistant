import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../renderer/blueprint_node.dart';
import '../../renderer/render_context.dart';

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
    return template.replaceAllMapped(
      RegExp(r'\{\{(\w+)\}\}'),
      (match) {
        final key = match.group(1)!;
        return _formatValue(data[key]);
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
