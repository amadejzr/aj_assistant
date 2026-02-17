import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../engine/action_dispatcher.dart';
import '../../renderer/blueprint_node.dart';
import '../../renderer/render_context.dart';

/// Renders a tappable button that dispatches a blueprint action, with elevated, outlined, and destructive style variants.
///
/// Blueprint JSON:
/// ```json
/// {"type": "button", "label": "Delete", "action": {"type": "delete_entry"}, "buttonStyle": "destructive"}
/// ```
///
/// - `label` (`String`, required): Text displayed on the button.
/// - `action` (`Map<String, dynamic>`, optional): Action configuration dispatched via `BlueprintActionDispatcher` on tap.
/// - `buttonStyle` (`String?`, optional): Visual style variant. One of `"outlined"`, `"destructive"`, or default elevated style.
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
            side: BorderSide(color: colors.error, width: 1.5),
            foregroundColor: colors.error,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
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
            side: BorderSide(color: colors.accent, width: 1.5),
            foregroundColor: colors.accent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
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
          backgroundColor: colors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
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
