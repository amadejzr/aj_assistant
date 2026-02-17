import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../renderer/render_context.dart';

/// Centralized action handler for blueprint actions.
///
/// Action types:
///   `navigate` — navigate to another screen
///   `navigate_back` — go back to previous screen
///   `submit` — submit the current form
///   `delete_entry` — delete an entry with optional confirmation
class BlueprintActionDispatcher {
  const BlueprintActionDispatcher._();

  static void dispatch(
    Map<String, dynamic> action,
    RenderContext ctx,
    BuildContext buildContext, {
    Map<String, dynamic> entryData = const {},
    String? entryId,
  }) {
    final type = action['type'] as String?;

    switch (type) {
      case 'navigate':
        final screen = action['screen'] as String?;
        if (screen != null) {
          final actionParams = Map<String, dynamic>.from(
            action['params'] as Map? ?? {},
          );
          final merged = {...ctx.screenParams, ...actionParams};
          ctx.onNavigateToScreen(screen, params: merged);
        }

      case 'navigate_back':
        ctx.onNavigateBack?.call();

      case 'submit':
        ctx.onFormSubmit?.call();

      case 'delete_entry':
        final id = entryId ?? ctx.screenParams['_entryId'] as String?;
        if (id == null || id.isEmpty) return;

        final confirm = action['confirm'] as bool? ?? false;
        if (confirm) {
          _showDeleteConfirmation(
            buildContext,
            action['confirmMessage'] as String? ?? 'Delete this entry?',
            () => _executeDelete(ctx, id),
          );
        } else {
          _executeDelete(ctx, id);
        }
    }
  }

  static void _executeDelete(RenderContext ctx, String entryId) {
    ctx.onDeleteEntry?.call(entryId);
  }

  static void _showDeleteConfirmation(
    BuildContext context,
    String message,
    VoidCallback onConfirm,
  ) {
    final colors = context.colors;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Confirm',
          style: TextStyle(
            fontFamily: 'Karla',
            fontWeight: FontWeight.w600,
            color: colors.onBackground,
          ),
        ),
        content: Text(
          message,
          style: TextStyle(fontFamily: 'Karla', color: colors.onBackground),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(fontFamily: 'Karla', color: colors.onBackgroundMuted),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              onConfirm();
            },
            child: Text(
              'Delete',
              style: TextStyle(
                fontFamily: 'Karla',
                color: colors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
