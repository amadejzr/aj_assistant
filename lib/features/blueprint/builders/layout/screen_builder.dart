import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/widgets/paper_background.dart';
import '../../engine/action_dispatcher.dart';
import '../../renderer/blueprint_node.dart';
import '../../renderer/render_context.dart';
import '../../renderer/widget_registry.dart';
import '../../utils/icon_resolver.dart';

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
    if (customActions.length <= 2) {
      actions = [
        for (final action in customActions) registry.build(action, ctx),
      ];
    } else {
      // Keep first action as icon button, collapse rest into overflow menu
      actions = [
        registry.build(customActions.first, ctx),
        _buildOverflowMenu(customActions.skip(1).toList(), ctx, colors),
      ];
    }
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

  // Show back button for deep navigation, hamburger menu for drawer, or nothing.
  Widget? leading;
  if (showBackButton) {
    leading = IconButton(
      icon: Icon(Icons.arrow_back, color: colors.onBackground),
      onPressed: () => ctx.onNavigateBack?.call(),
    );
  } else if (ctx.onOpenDrawer != null) {
    leading = IconButton(
      icon: Icon(Icons.menu, color: colors.onBackground),
      onPressed: () => ctx.onOpenDrawer!.call(),
    );
  }

  // Interpolate {{key}} template expressions in the title.
  final resolvedTitle = title != null ? _interpolateTitle(title, ctx) : null;

  return AppBar(
    backgroundColor: colors.background,
    elevation: 0,
    leading: leading,
    title: resolvedTitle != null
        ? Text(
            resolvedTitle,
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

/// Builds a PopupMenuButton from overflow [BlueprintNode] actions.
Widget _buildOverflowMenu(
  List<BlueprintNode> nodes,
  RenderContext ctx,
  dynamic colors,
) {
  final items = <_OverflowItem>[];
  for (final node in nodes) {
    if (node is IconButtonNode) {
      items.add(_OverflowItem(
        label: node.tooltip ?? node.icon,
        icon: resolveIcon(node.icon) ??
            PhosphorIcons.circle(PhosphorIconsStyle.regular),
        action: node.action,
      ));
    }
  }

  return _OverflowMenuButton(items: items, ctx: ctx);
}

class _OverflowItem {
  final String label;
  final IconData icon;
  final Map<String, dynamic> action;
  const _OverflowItem({
    required this.label,
    required this.icon,
    required this.action,
  });
}

class _OverflowMenuButton extends StatelessWidget {
  final List<_OverflowItem> items;
  final RenderContext ctx;

  const _OverflowMenuButton({required this.items, required this.ctx});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return PopupMenuButton<int>(
      icon: Icon(
        PhosphorIcons.dotsThreeVertical(PhosphorIconsStyle.regular),
        color: colors.onBackground,
      ),
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.border),
      ),
      itemBuilder: (_) => [
        for (var i = 0; i < items.length; i++)
          PopupMenuItem<int>(
            value: i,
            child: Row(
              children: [
                Icon(items[i].icon, size: 18, color: colors.onBackground),
                const SizedBox(width: 12),
                Text(
                  items[i].label,
                  style: TextStyle(
                    fontFamily: 'Karla',
                    fontSize: 14,
                    color: colors.onBackground,
                  ),
                ),
              ],
            ),
          ),
      ],
      onSelected: (index) {
        BlueprintActionDispatcher.dispatch(items[index].action, ctx, context);
      },
    );
  }
}

String _interpolateTitle(String template, RenderContext ctx) {
  final data = {...ctx.screenParams, ...ctx.formValues};
  return template.replaceAllMapped(
    RegExp(r'\{\{([\w.]+)\}\}'),
    (match) {
      final key = match.group(1)!;
      final value = data[key];
      return value?.toString() ?? '';
    },
  );
}
