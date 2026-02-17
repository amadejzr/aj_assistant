import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../action_dispatcher.dart';
import '../blueprint_node.dart';
import '../render_context.dart';

Widget buildButton(BlueprintNode node, RenderContext ctx) {
  final button = node as ButtonNode;
  return _ButtonWidget(button: button, ctx: ctx);
}

class _ButtonWidget extends StatelessWidget {
  final ButtonNode button;
  final RenderContext ctx;

  const _ButtonWidget({required this.button, required this.ctx});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final isOutlined = button.buttonStyle == 'outlined';
    final isDestructive = button.buttonStyle == 'destructive';
    final isPrimary = button.buttonStyle == 'primary';

    void handleAction() {
      BlueprintActionDispatcher.dispatch(
        button.action,
        ctx,
        context,
        entryId: ctx.screenParams['_entryId'] as String?,
      );
    }

    if (isDestructive) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: OutlinedButton(
          onPressed: handleAction,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: colors.error),
            foregroundColor: colors.error,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: TextStyle(
              fontFamily: 'Karla',
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: Text(button.label),
        ),
      );
    }

    if (isOutlined) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: OutlinedButton(
          onPressed: handleAction,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: colors.accent),
            foregroundColor: colors.accent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: TextStyle(
              fontFamily: 'Karla',
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: Text(button.label),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ElevatedButton(
        onPressed: handleAction,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? colors.accent : colors.accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: TextStyle(
            fontFamily: 'Karla',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: Text(button.label),
      ),
    );
  }
}
