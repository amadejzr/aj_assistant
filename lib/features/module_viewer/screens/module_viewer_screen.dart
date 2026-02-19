import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/entry.dart';
import '../../../core/repositories/entry_repository.dart';
import '../../../core/repositories/module_repository.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../features/auth/bloc/auth_bloc.dart';
import '../../../features/auth/bloc/auth_state.dart';
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

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ModuleViewerBloc>();
    final screenId = state.currentScreenId;

    final blueprint = state.module.screens[screenId];

    final Widget child;

    if (blueprint == null) {
      child = Scaffold(
        key: ValueKey('notfound_$screenId'),
        appBar: AppBar(title: Text(state.module.name)),
        body: const Center(child: Text('Screen not found')),
      );
    } else {
      final entryRepo = context.read<EntryRepository>();
      final authState = context.read<AuthBloc>().state;
      final userId =
          authState is AuthAuthenticated ? authState.user.uid : '';

      final renderContext = RenderContext(
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
            schemaVersion:
                state.module.schemas[schemaKey]?.version ?? 1,
            schemaKey: schemaKey,
          );
          return entryRepo.createEntry(userId, state.module.id, entry);
        },
        onUpdateEntry: (entryId, schemaKey, data) async {
          final existing = state.entries
              .where((e) => e.id == entryId)
              .firstOrNull;
          final mergedData = {
            if (existing != null) ...existing.data,
            ...data,
          };
          final updated = Entry(
            id: entryId,
            data: mergedData,
            schemaVersion:
                state.module.schemas[schemaKey]?.version ?? 1,
            schemaKey: schemaKey,
          );
          await entryRepo.updateEntry(userId, state.module.id, updated);
        },
      );

      child = BlueprintRenderer(
        key: ValueKey(screenId),
        blueprintJson: blueprint,
        context_: renderContext,
      );
    }

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
