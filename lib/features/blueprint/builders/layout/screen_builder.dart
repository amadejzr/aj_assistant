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
    final customAppBar = screen.appBar;

    return PopScope(
      canPop: !canGoBack,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && canGoBack) {
          ctx.onNavigateBack?.call();
        }
      },
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: buildBlueprintAppBar(
          colors: colors,
          ctx: ctx,
          registry: registry,
          canGoBack: canGoBack,
          title: customAppBar?.title ?? screen.title,
          showBack: customAppBar?.showBack ?? true,
          customActions: customAppBar?.actions,
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

/// Builds an AppBar from either custom [AppBarNode] actions or default info/settings buttons.
///
/// Shared between screen_builder and tab_screen_builder.
AppBar buildBlueprintAppBar({
  required dynamic colors,
  required RenderContext ctx,
  required WidgetRegistry registry,
  required bool canGoBack,
  String? title,
  bool showBack = true,
  List<BlueprintNode>? customActions,
}) {
  final showBackButton = canGoBack && showBack;

  List<Widget> actions;
  if (customActions != null && customActions.isNotEmpty) {
    actions = [
      for (final action in customActions) registry.build(action, ctx),
    ];
  } else {
    actions = [
      IconButton(
        icon: Icon(Icons.info_outline, color: colors.onBackgroundMuted),
        onPressed: () => ctx.onNavigateToScreen('_info', params: const {}),
      ),
      IconButton(
        icon: Icon(Icons.settings, color: colors.onBackgroundMuted),
        onPressed: () => ctx.onNavigateToScreen('_settings', params: const {}),
      ),
    ];
  }

  return AppBar(
    backgroundColor: colors.background,
    elevation: 0,
    leading: showBackButton
        ? IconButton(
            icon: Icon(Icons.arrow_back, color: colors.onBackground),
            onPressed: () => ctx.onNavigateBack?.call(),
          )
        : null,
    title: title != null
        ? Text(
            title,
            style: TextStyle(
              fontFamily: 'CormorantGaramond',
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: colors.onBackground,
            ),
          )
        : null,
    iconTheme: IconThemeData(color: colors.onBackground),
    actions: actions,
  );
}
