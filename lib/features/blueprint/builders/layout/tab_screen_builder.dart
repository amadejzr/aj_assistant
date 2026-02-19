import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/widgets/paper_background.dart';
import '../../renderer/blueprint_node.dart';
import '../../renderer/render_context.dart';
import '../../renderer/widget_registry.dart';
import '../../utils/icon_resolver.dart';
import 'screen_builder.dart' show buildBlueprintAppBar;

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

class _TabScreenShell extends StatefulWidget {
  final TabScreenNode tabScreen;
  final RenderContext ctx;

  const _TabScreenShell({required this.tabScreen, required this.ctx});

  @override
  State<_TabScreenShell> createState() => _TabScreenShellState();
}

class _TabScreenShellState extends State<_TabScreenShell>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    final initialIndex = widget.ctx.screenParams['_tabIndex'] as int? ?? 0;
    _tabController = TabController(
      length: widget.tabScreen.tabs.length,
      vsync: this,
      initialIndex: initialIndex.clamp(0, widget.tabScreen.tabs.length - 1),
    );
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      widget.ctx.onScreenParamChanged?.call('_tabIndex', _tabController.index);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final registry = WidgetRegistry.instance;
    final ctx = widget.ctx;
    final tabScreen = widget.tabScreen;

    Widget? fab;
    if (tabScreen.fab != null) {
      fab = registry.build(tabScreen.fab!, ctx);
    }

    final canGoBack = ctx.canGoBack;
    final customAppBar = tabScreen.appBar;

    final baseAppBar = buildBlueprintAppBar(
      colors: colors,
      ctx: ctx,
      registry: registry,
      canGoBack: canGoBack,
      title: customAppBar?.title ?? tabScreen.title,
      showBack: customAppBar?.showBack ?? true,
      customActions: customAppBar?.actions,
    );

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
          backgroundColor: baseAppBar.backgroundColor,
          elevation: baseAppBar.elevation,
          leading: baseAppBar.leading,
          title: baseAppBar.title,
          iconTheme: baseAppBar.iconTheme,
          actions: baseAppBar.actions,
          bottom: TabBar(
            controller: _tabController,
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
              final icon = resolveIcon(tab.icon);
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
              controller: _tabController,
              children: tabScreen.tabs.map((tab) {
                return registry.build(tab.content, ctx);
              }).toList(),
            ),
          ],
        ),
        floatingActionButton: fab,
      ),
    );
  }
}
