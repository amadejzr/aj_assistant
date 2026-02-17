import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/widgets/paper_background.dart';
import '../../renderer/blueprint_node.dart';
import '../../renderer/render_context.dart';
import '../../renderer/widget_registry.dart';

/// Renders a full-screen scaffold with an app bar, paper background, and optional FAB.
///
/// Blueprint JSON:
/// ```json
/// {"type": "screen", "title": "Expenses", "children": [], "fab": {"type": "fab", "icon": "add", "action": {}}}
/// ```
///
/// - `title` (`String?`, optional): Title displayed in the app bar.
/// - `children` (`List<BlueprintNode>`, optional): Child widgets rendered in a column within the screen body.
/// - `fab` (`BlueprintNode?`, optional): A floating action button node rendered at the bottom-right.
Widget buildScreen(BlueprintNode node, RenderContext ctx) {
  final screen = node as ScreenNode;
  return _ScreenShell(screen: screen, ctx: ctx);
}

class _ScreenShell extends StatelessWidget {
  final ScreenNode screen;
  final RenderContext ctx;

  const _ScreenShell({required this.screen, required this.ctx});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final registry = WidgetRegistry.instance;

    Widget? fab;
    if (screen.fab != null) {
      fab = registry.build(screen.fab!, ctx);
    }

    final canGoBack = ctx.canGoBack;

    return PopScope(
      canPop: !canGoBack,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && canGoBack) {
          ctx.onNavigateBack?.call();
        }
      },
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          backgroundColor: colors.background,
          elevation: 0,
          leading: canGoBack
              ? IconButton(
                  icon: Icon(Icons.arrow_back, color: colors.onBackground),
                  onPressed: () => ctx.onNavigateBack?.call(),
                )
              : null,
          title: screen.title != null
              ? Text(
                  screen.title!,
                  style: TextStyle(
                    fontFamily: 'CormorantGaramond',
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    color: colors.onBackground,
                  ),
                )
              : null,
          iconTheme: IconThemeData(color: colors.onBackground),
          actions: [
            IconButton(
              icon: Icon(Icons.settings, color: colors.onBackgroundMuted),
              onPressed: () => ctx.onNavigateToScreen(
                '_settings',
                params: const {},
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            PaperBackground(colors: colors),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                ),
                child: Column(
                  children: [
                    for (final child in screen.children)
                      Expanded(child: registry.build(child, ctx)),
                  ],
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: fab,
      ),
    );
  }
}
