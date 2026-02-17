import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/widgets/paper_background.dart';
import '../../renderer/blueprint_node.dart';
import '../../renderer/render_context.dart';
import '../../renderer/widget_registry.dart';

/// Renders a tabbed screen scaffold with a tab bar, paper background, and optional FAB.
///
/// Blueprint JSON:
/// ```json
/// {"type": "tab_screen", "title": "Tracker", "tabs": [{"label": "List", "icon": "list", "content": {"type": "scroll_column", "children": []}}]}
/// ```
///
/// - `title` (`String?`, optional): Title displayed in the app bar.
/// - `tabs` (`List<TabDef>`, optional): Tab definitions, each with a label, optional icon, and content node.
/// - `fab` (`BlueprintNode?`, optional): A floating action button node rendered at the bottom-right.
Widget buildTabScreen(BlueprintNode node, RenderContext ctx) {
  final tab = node as TabScreenNode;
  return _TabScreenShell(tabScreen: tab, ctx: ctx);
}

class _TabScreenShell extends StatelessWidget {
  final TabScreenNode tabScreen;
  final RenderContext ctx;

  const _TabScreenShell({required this.tabScreen, required this.ctx});

  IconData? _resolveIcon(String? iconName) {
    return switch (iconName) {
      'list' => PhosphorIcons.listBullets(PhosphorIconsStyle.regular),
      'chart' => PhosphorIcons.chartBar(PhosphorIconsStyle.regular),
      'calendar' => PhosphorIcons.calendar(PhosphorIconsStyle.regular),
      'settings' => PhosphorIcons.gear(PhosphorIconsStyle.regular),
      'activity' => PhosphorIcons.lightning(PhosphorIconsStyle.regular),
      'stats' => PhosphorIcons.trendUp(PhosphorIconsStyle.regular),
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final registry = WidgetRegistry.instance;

    Widget? fab;
    if (tabScreen.fab != null) {
      fab = registry.build(tabScreen.fab!, ctx);
    }

    final canGoBack = ctx.canGoBack;

    return PopScope(
      canPop: !canGoBack,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && canGoBack) {
          ctx.onNavigateBack?.call();
        }
      },
      child: DefaultTabController(
        length: tabScreen.tabs.length,
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
            title: tabScreen.title != null
                ? Text(
                    tabScreen.title!,
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
            bottom: TabBar(
              indicatorColor: colors.accent,
              indicatorWeight: 2.5,
              labelColor: colors.accent,
              unselectedLabelColor: colors.onBackgroundMuted,
              labelStyle: TextStyle(
                fontFamily: 'Karla',
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: TextStyle(
                fontFamily: 'Karla',
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              tabs: tabScreen.tabs.map((tab) {
                final icon = _resolveIcon(tab.icon);
                if (icon != null) {
                  return Tab(
                    icon: Icon(icon, size: 20),
                    text: tab.label,
                  );
                }
                return Tab(text: tab.label);
              }).toList(),
            ),
          ),
          body: Stack(
            children: [
              PaperBackground(colors: colors),
              TabBarView(
                children: tabScreen.tabs.map((tab) {
                  return registry.build(tab.content, ctx);
                }).toList(),
              ),
            ],
          ),
          floatingActionButton: fab,
        ),
      ),
    );
  }
}
