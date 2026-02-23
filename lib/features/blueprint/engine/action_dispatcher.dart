import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../builders/layout/form_screen_builder.dart';
import '../renderer/blueprint_node.dart';
import '../renderer/blueprint_parser.dart';
import '../renderer/render_context.dart';

/// Centralized action handler for blueprint actions.
///
/// Action types:
///   `navigate` — navigate to another screen
///   `navigate_back` — go back to previous screen
///   `submit` — submit the current form
///   `delete_entry` — delete an entry with optional confirmation
///   `show_form_sheet` — show a form_screen blueprint in a modal bottom sheet
///   `confirm` — show confirmation dialog before executing inner action
///   `toast` — show a snackbar message
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
        final actionType = action['action'] as String?;
        if (actionType == 'show_form_sheet') {
          _showFormSheet(action, ctx, buildContext);
        } else {
          final screen = action['screen'] as String?;
          if (screen != null) {
            final actionParams = Map<String, dynamic>.from(
              action['params'] as Map? ?? {},
            );
            final merged = {...ctx.screenParams, ...actionParams};
            ctx.onNavigateToScreen(screen, params: merged);
          }
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

      case 'show_form_sheet':
        _showFormSheet(action, ctx, buildContext);

      case 'confirm':
        _showConfirmDialog(action, ctx, buildContext, entryData: entryData, entryId: entryId);

      case 'toast':
        final message = action['message'] as String? ?? '';
        if (message.isNotEmpty && buildContext.mounted) {
          ScaffoldMessenger.of(buildContext).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
    }
  }

  static void _executeDelete(RenderContext ctx, String entryId) {
    ctx.onDeleteEntry?.call(entryId);
  }

  static void _showFormSheet(
    Map<String, dynamic> action,
    RenderContext ctx,
    BuildContext buildContext,
  ) {
    final screenId = action['screen'] as String?;
    if (screenId == null) return;

    final screenDef = ctx.module.screens[screenId];
    if (screenDef == null) return;

    final parser = BlueprintParser(fieldSets: ctx.module.fieldSets);
    final node = parser.parse(screenDef);
    if (node is! FormScreenNode) return;

    final title = action['title'] as String? ?? node.title;
    final actionParams = Map<String, dynamic>.from(
      action['params'] as Map? ?? {},
    );
    final sheetParams = {...ctx.screenParams, ...actionParams};

    showModalBottomSheet<void>(
      context: buildContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _FormSheetWrapper(
          form: node,
          title: title,
          screenId: screenId,
          ctx: ctx,
          sheetParams: sheetParams,
        );
      },
    );
  }

  static void _showConfirmDialog(
    Map<String, dynamic> action,
    RenderContext ctx,
    BuildContext buildContext, {
    Map<String, dynamic> entryData = const {},
    String? entryId,
  }) {
    final title = action['title'] as String? ?? 'Confirm';
    final message = action['message'] as String? ?? 'Are you sure?';
    final onConfirm = action['onConfirm'] as Map<String, dynamic>?;
    if (onConfirm == null) return;

    final colors = buildContext.colors;

    showDialog(
      context: buildContext,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
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
              dispatch(onConfirm, ctx, buildContext,
                  entryData: entryData, entryId: entryId);
            },
            child: Text(
              'Confirm',
              style: TextStyle(
                fontFamily: 'Karla',
                color: colors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
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

/// Stateful wrapper that manages form state for bottom sheet forms.
///
/// This creates its own mini form-value map so the sheet's form state
/// is isolated from the main screen. On submit, it creates/updates the
/// entry and applies post-submit effects via the existing RenderContext
/// callbacks, then dismisses the sheet.
class _FormSheetWrapper extends StatefulWidget {
  final FormScreenNode form;
  final String? title;
  final String screenId;
  final RenderContext ctx;
  final Map<String, dynamic> sheetParams;

  const _FormSheetWrapper({
    required this.form,
    required this.title,
    required this.screenId,
    required this.ctx,
    required this.sheetParams,
  });

  @override
  State<_FormSheetWrapper> createState() => _FormSheetWrapperState();
}

class _FormSheetWrapperState extends State<_FormSheetWrapper> {
  late Map<String, dynamic> _formValues;

  @override
  void initState() {
    super.initState();
    _formValues = {};
  }

  void _onFormValueChanged(String key, dynamic value) {
    setState(() {
      _formValues[key] = value;
    });
  }

  Future<void> _onSubmit() async {
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // Build a sheet-local RenderContext with isolated form state
    final sheetCtx = RenderContext(
      module: widget.ctx.module,
      formValues: _formValues,
      screenParams: widget.sheetParams,
      canGoBack: false,
      onFormValueChanged: _onFormValueChanged,
      onFormSubmit: _onSubmit,
      onNavigateToScreen: widget.ctx.onNavigateToScreen,
      onNavigateBack: () => Navigator.of(context).pop(),
      onDeleteEntry: widget.ctx.onDeleteEntry,
      resolvedExpressions: widget.ctx.resolvedExpressions,
      onScreenParamChanged: widget.ctx.onScreenParamChanged,
    );

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Sheet handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Title
          if (widget.title != null)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
                vertical: AppSpacing.sm,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.title!,
                  style: TextStyle(
                    fontFamily: 'CormorantGaramond',
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: colors.onBackground,
                  ),
                ),
              ),
            ),
          // Form body
          Flexible(
            child: FormBody(
              form: widget.form,
              ctx: sheetCtx,
              isSheet: true,
            ),
          ),
        ],
      ),
    );
  }
}

