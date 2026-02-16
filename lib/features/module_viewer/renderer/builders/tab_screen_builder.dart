import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/widgets/paper_background.dart';
import '../blueprint_node.dart';
import '../render_context.dart';
import '../widget_registry.dart';

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
                    style: GoogleFonts.cormorantGaramond(
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
              labelStyle: GoogleFonts.karla(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: GoogleFonts.karla(
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
