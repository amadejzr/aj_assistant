import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/entry.dart';
import '../../../core/repositories/entry_repository.dart';
import '../../../core/repositories/module_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../features/auth/bloc/auth_bloc.dart';
import '../../../features/auth/bloc/auth_state.dart';
import '../../blueprint/navigation/module_navigation.dart';
import '../../blueprint/utils/icon_resolver.dart';
import '../bloc/module_viewer_bloc.dart';
import '../bloc/module_viewer_event.dart';
import '../bloc/module_viewer_state.dart';
import '../../blueprint/renderer/blueprint_renderer.dart';
import '../../blueprint/renderer/render_context.dart';

class ModuleViewerScreen extends StatelessWidget {
  final String moduleId;

  const ModuleViewerScreen({super.key, required this.moduleId});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final userId = authState is AuthAuthenticated ? authState.user.uid : '';

    return BlocProvider(
      create: (context) => ModuleViewerBloc(
        moduleRepository: context.read<ModuleRepository>(),
        entryRepository: context.read<EntryRepository>(),
        userId: userId,
      )..add(ModuleViewerStarted(moduleId)),
      child: const _ModuleViewerBody(),
    );
  }
}

class _ModuleViewerBody extends StatelessWidget {
  const _ModuleViewerBody();

  @override
  Widget build(BuildContext context) {
    return BlocListener<ModuleViewerBloc, ModuleViewerState>(
      listenWhen: (prev, curr) {
        final prevError =
            prev is ModuleViewerLoaded ? prev.submitError : null;
        final currError =
            curr is ModuleViewerLoaded ? curr.submitError : null;
        return currError != null && currError != prevError;
      },
      listener: (context, state) {
        if (state is ModuleViewerLoaded && state.submitError != null) {
          AppToast.show(
            context,
            message: state.submitError!,
            type: AppToastType.error,
          );
        }
      },
      child: BlocBuilder<ModuleViewerBloc, ModuleViewerState>(
        builder: (context, state) {
          return switch (state) {
            ModuleViewerInitial() || ModuleViewerLoading() => const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
            ModuleViewerError(:final message) => Scaffold(
                appBar: AppBar(title: const Text('Error')),
                body: Center(child: Text(message)),
              ),
            ModuleViewerLoaded() => _LoadedView(state: state),
          };
        },
      ),
    );
  }
}

class _LoadedView extends StatelessWidget {
  final ModuleViewerLoaded state;

  const _LoadedView({required this.state});

  RenderContext _buildRenderContext(BuildContext context) {
    final bloc = context.read<ModuleViewerBloc>();
    final entryRepo = context.read<EntryRepository>();
    final authState = context.read<AuthBloc>().state;
    final userId = authState is AuthAuthenticated ? authState.user.uid : '';

    return RenderContext(
      module: state.module,
      entries: state.entries,
      allEntries: state.entries,
      formValues: state.formValues,
      screenParams: state.screenParams,
      canGoBack: state.canGoBack,
      resolvedExpressions: state.resolvedExpressions,
      onFormValueChanged: (fieldKey, value) {
        bloc.add(ModuleViewerFormValueChanged(fieldKey, value));
      },
      onFormSubmit: () {
        bloc.add(const ModuleViewerFormSubmitted());
      },
      onNavigateToScreen: (screenId,
          {Map<String, dynamic> params = const {}}) {
        if (screenId == '_info') {
          context.push('/module/${state.module.id}/info');
          return;
        }
        if (screenId == '_settings') {
          context
              .push('/module/${state.module.id}/info')
              .then((_) => bloc.add(const ModuleViewerModuleRefreshed()));
          return;
        }
        bloc.add(ModuleViewerScreenChanged(screenId, params: params));
      },
      onNavigateBack: () {
        bloc.add(const ModuleViewerNavigateBack());
      },
      onDeleteEntry: (entryId) {
        bloc.add(ModuleViewerEntryDeleted(entryId));
      },
      onScreenParamChanged: (key, value) {
        bloc.add(ModuleViewerScreenParamChanged(key, value));
      },
      onCreateEntry: (schemaKey, data) async {
        final entry = Entry(
          id: '',
          data: data,
          schemaVersion: state.module.schemas[schemaKey]?.version ?? 1,
          schemaKey: schemaKey,
        );
        return entryRepo.createEntry(userId, state.module.id, entry);
      },
      onUpdateEntry: (entryId, schemaKey, data) async {
        final existing =
            state.entries.where((e) => e.id == entryId).firstOrNull;
        final mergedData = {
          if (existing != null) ...existing.data,
          ...data,
        };
        final updated = Entry(
          id: entryId,
          data: mergedData,
          schemaVersion: state.module.schemas[schemaKey]?.version ?? 1,
          schemaKey: schemaKey,
        );
        await entryRepo.updateEntry(userId, state.module.id, updated);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ModuleViewerBloc>();
    final screenId = state.currentScreenId;
    final blueprint = state.module.screens[screenId];
    final nav = state.module.navigation;

    final Widget child;

    if (blueprint == null) {
      child = Scaffold(
        key: ValueKey('notfound_$screenId'),
        appBar: AppBar(title: Text(state.module.name)),
        body: const Center(child: Text('Screen not found')),
      );
    } else {
      final renderContext = _buildRenderContext(context);
      child = BlueprintRenderer(
        key: ValueKey(screenId),
        blueprintJson: blueprint,
        context_: renderContext,
      );
    }

    // Wrap with bottom nav / drawer if configured
    final bottomNavItems = nav?.bottomNav?.items;
    final hasBottomNav = bottomNavItems != null && bottomNavItems.length >= 2;
    final drawerNav = nav?.drawer;
    final hasDrawer = drawerNav != null && drawerNav.items.isNotEmpty;

    if (!hasBottomNav && !hasDrawer) {
      return _animatedSwitch(child);
    }

    // Only show nav chrome on tab screens, not on deep screens (forms, etc.)
    final isOnTab = hasBottomNav &&
        bottomNavItems.any((item) => item.screenId == screenId);

    // Build bottom nav bar
    BottomNavigationBar? bottomNavBar;
    if (hasBottomNav && isOnTab) {
      final currentIndex = _navIndex(bottomNavItems, screenId);

      bottomNavBar = BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          final target = bottomNavItems[index].screenId;
          if (target != screenId) {
            bloc.add(ModuleViewerScreenChanged(target, clearStack: true));
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: context.colors.surface,
        selectedItemColor: context.colors.accent,
        unselectedItemColor: context.colors.onBackgroundMuted,
        selectedLabelStyle: const TextStyle(fontFamily: 'Karla', fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontFamily: 'Karla', fontSize: 12),
        items: bottomNavItems.map((item) {
          final icon = resolveIcon(item.icon);
          return BottomNavigationBarItem(
            icon: Icon(icon ?? Icons.circle, size: 22),
            label: item.label,
          );
        }).toList(),
      );
    }

    // Build drawer (only on tab screens)
    Widget? drawer;
    if (hasDrawer && isOnTab) {
      drawer = _buildDrawer(context, drawerNav, screenId, bloc);
    }

    return _ModuleNavShell(
      bottomNavBar: bottomNavBar,
      drawer: drawer,
      child: _animatedSwitch(child),
    );
  }

  int _navIndex(List<NavItem> items, String screenId) {
    final idx = items.indexWhere((item) => item.screenId == screenId);
    return idx >= 0 ? idx : 0;
  }

  Widget _buildDrawer(
    BuildContext context,
    DrawerNav drawerNav,
    String screenId,
    ModuleViewerBloc bloc,
  ) {
    final colors = context.colors;

    return Drawer(
      backgroundColor: colors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (drawerNav.header != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  drawerNav.header!,
                  style: TextStyle(
                    fontFamily: 'CormorantGaramond',
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: colors.onBackground,
                  ),
                ),
              ),
            const Divider(),
            for (final item in drawerNav.items)
              ListTile(
                leading: Icon(
                  resolveIcon(item.icon) ?? Icons.circle,
                  color: item.screenId == screenId
                      ? colors.accent
                      : colors.onBackgroundMuted,
                  size: 22,
                ),
                title: Text(
                  item.label,
                  style: TextStyle(
                    fontFamily: 'Karla',
                    color: item.screenId == screenId
                        ? colors.accent
                        : colors.onBackground,
                    fontWeight: item.screenId == screenId
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
                selected: item.screenId == screenId,
                onTap: () {
                  Navigator.of(context).pop(); // close drawer
                  if (item.screenId != screenId) {
                    bloc.add(ModuleViewerScreenChanged(item.screenId, clearStack: true));
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _animatedSwitch(Widget child) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.04, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Shell widget that wraps a BlueprintRenderer-produced Scaffold with
/// bottom navigation and/or drawer support.
///
/// Since the inner [child] is already a Scaffold (from screen_builder),
/// this uses a [Column] layout to overlay the bottom nav below the inner
/// scaffold, and wraps everything in an outer Scaffold for the drawer.
class _ModuleNavShell extends StatelessWidget {
  final BottomNavigationBar? bottomNavBar;
  final Widget? drawer;
  final Widget child;

  const _ModuleNavShell({
    this.bottomNavBar,
    this.drawer,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (drawer != null) {
      // Wrap in outer Scaffold for drawer support
      return Scaffold(
        backgroundColor: Colors.transparent,
        drawer: drawer,
        body: Column(
          children: [
            Expanded(child: child),
            ?bottomNavBar,
          ],
        ),
      );
    }

    if (bottomNavBar != null) {
      return Column(
        children: [
          Expanded(child: child),
          bottomNavBar!,
        ],
      );
    }

    return child;
  }
}
