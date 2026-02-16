import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../action_dispatcher.dart';
import '../blueprint_node.dart';
import '../render_context.dart';

Widget buildEntryCard(BlueprintNode node, RenderContext ctx) {
  final card = node as EntryCardNode;
  return _EntryCardWidget(card: card, ctx: ctx);
}

class _EntryCardWidget extends StatelessWidget {
  final EntryCardNode card;
  final RenderContext ctx;

  const _EntryCardWidget({required this.card, required this.ctx});

  String _formatValue(dynamic value) {
    if (value == null) return '';
    final str = value.toString();

    // Try parsing as a date (ISO 8601)
    final date = DateTime.tryParse(str);
    if (date != null) {
      if (date.hour == 0 && date.minute == 0 && date.second == 0) {
        return DateFormat.yMMMd().format(date);
      }
      return DateFormat.yMMMd().add_jm().format(date);
    }

    // Try parsing as time-only (HH:mm)
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

  String _interpolate(String template, Map<String, dynamic> data) {
    return template.replaceAllMapped(
      RegExp(r'\{\{(\w+)\}\}'),
      (match) {
        final key = match.group(1)!;
        final value = data[key];
        return _formatValue(value);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final data = ctx.formValues;
    final entryId =
        ctx.entries.isNotEmpty ? ctx.entries.first.id : null;

    final title =
        card.titleTemplate != null ? _interpolate(card.titleTemplate!, data) : '';
    final subtitle = card.subtitleTemplate != null
        ? _interpolate(card.subtitleTemplate!, data)
        : null;
    final trailing = card.trailingTemplate != null
        ? _interpolate(card.trailingTemplate!, data)
        : null;

    final hasTap = card.onTap.isNotEmpty;

    final content = Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.karla(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: colors.onBackground,
                  ),
                ),
                if (subtitle != null && subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.karla(
                      fontSize: 13,
                      color: colors.onBackgroundMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null && trailing.isNotEmpty)
            Text(
              trailing,
              style: GoogleFonts.karla(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colors.accent,
              ),
            ),
          if (hasTap) ...[
            const SizedBox(width: AppSpacing.sm),
            Icon(
              PhosphorIcons.caretRight(PhosphorIconsStyle.regular),
              size: 16,
              color: colors.onBackgroundMuted,
            ),
          ],
        ],
      ),
    );

    Widget tappable = content;
    if (hasTap) {
      tappable = GestureDetector(
        onTap: () {
          final screen = card.onTap['screen'] as String?;
          if (screen == null) return;

          final forwardFields = card.onTap['forwardFields'] as List?;
          final params = <String, dynamic>{...ctx.screenParams};

          if (forwardFields != null) {
            for (final field in forwardFields) {
              final key = field.toString();
              if (data.containsKey(key)) {
                params[key] = data[key];
              }
            }
          }

          // Forward entry ID so forms can update instead of create
          if (entryId != null) {
            params['_entryId'] = entryId;
          }

          ctx.onNavigateToScreen(screen, params: params);
        },
        child: content,
      );
    }

    // Wrap in Dismissible if swipeActions are defined
    final rightAction = card.swipeActions['right'] as Map<String, dynamic>?;
    if (rightAction != null && entryId != null) {
      return Dismissible(
        key: ValueKey('swipe_$entryId'),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) async {
          final confirm = rightAction['confirm'] as bool? ?? false;
          if (!confirm) return true;
          return _showConfirmDialog(
            context,
            rightAction['confirmMessage'] as String? ?? 'Delete this entry?',
            colors,
          );
        },
        onDismissed: (_) {
          BlueprintActionDispatcher.dispatch(
            rightAction,
            ctx,
            context,
            entryId: entryId,
          );
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: AppSpacing.lg),
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          decoration: BoxDecoration(
            color: colors.error,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        child: tappable,
      );
    }

    return tappable;
  }

  Future<bool> _showConfirmDialog(
    BuildContext context,
    String message,
    dynamic colors,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Confirm',
          style: GoogleFonts.karla(
            fontWeight: FontWeight.w600,
            color: colors.onBackground,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.karla(color: colors.onBackground),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.karla(color: colors.onBackgroundMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: Text(
              'Delete',
              style: GoogleFonts.karla(
                color: colors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
