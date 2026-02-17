import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/entry.dart';
import '../../../core/repositories/entry_repository.dart';
import '../../../core/repositories/module_repository.dart';
import '../../../features/auth/bloc/auth_bloc.dart';
import '../../../features/auth/bloc/auth_state.dart';
import '../bloc/module_viewer_bloc.dart';
import '../bloc/module_viewer_event.dart';
import '../bloc/module_viewer_state.dart';
import '../../blueprint/renderer/blueprint_renderer.dart';
import '../../blueprint/renderer/render_context.dart';
import '../../schema/bloc/schema_bloc.dart';
import '../../schema/bloc/schema_event.dart';
import '../../schema/bloc/schema_state.dart';
import '../../schema/screens/schema_navigator.dart';

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
    return BlocBuilder<ModuleViewerBloc, ModuleViewerState>(
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

    // Route settings to SchemaBloc-managed navigator
    if (screenId == '_settings') {
      final authState = context.read<AuthBloc>().state;
      final userId = authState is AuthAuthenticated ? authState.user.uid : '';

      return BlocProvider(
        create: (context) => SchemaBloc(
          moduleRepository: context.read<ModuleRepository>(),
          userId: userId,
          moduleId: state.module.id,
        )..add(SchemaStarted(state.module.id)),
        child: _SchemaNavigatorWithRefresh(
          onPop: () => bloc.add(const ModuleViewerNavigateBack()),
          onSchemasChanged: () =>
              bloc.add(const ModuleViewerModuleRefreshed()),
        ),
      );
    }

    // Unknown underscore-prefixed screens
    if (screenId.startsWith('_')) {
      return Scaffold(
        appBar: AppBar(title: const Text('Unknown')),
        body: const Center(child: Text('Unknown settings screen')),
      );
    }

    final blueprint = state.module.screens[screenId];

    if (blueprint == null) {
      return Scaffold(
        appBar: AppBar(title: Text(state.module.name)),
        body: const Center(child: Text('Screen not found')),
      );
    }

    final entryRepo = context.read<EntryRepository>();
    final authState = context.read<AuthBloc>().state;
    final userId = authState is AuthAuthenticated ? authState.user.uid : '';

    final renderContext = RenderContext(
      module: state.module,
      entries: state.entries,
      allEntries: state.entries,
      formValues: state.formValues,
      screenParams: state.screenParams,
      canGoBack: state.canGoBack,
      onFormValueChanged: (fieldKey, value) {
        bloc.add(ModuleViewerFormValueChanged(fieldKey, value));
      },
      onFormSubmit: () {
        bloc.add(const ModuleViewerFormSubmitted());
      },
      onNavigateToScreen: (screenId, {Map<String, dynamic> params = const {}}) {
        bloc.add(ModuleViewerScreenChanged(screenId, params: params));
      },
      onNavigateBack: () {
        bloc.add(const ModuleViewerNavigateBack());
      },
      onDeleteEntry: (entryId) {
        bloc.add(ModuleViewerEntryDeleted(entryId));
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

    return BlueprintRenderer(
      blueprintJson: blueprint,
      context_: renderContext,
    );
  }
}

/// Wraps SchemaNavigator to detect when the schema list's back button is
/// pressed (stack empty → pop back to module viewer) and to refresh the
/// module after schema edits.
class _SchemaNavigatorWithRefresh extends StatelessWidget {
  final VoidCallback onPop;
  final VoidCallback onSchemasChanged;

  const _SchemaNavigatorWithRefresh({
    required this.onPop,
    required this.onSchemasChanged,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<SchemaBloc, SchemaState>(
      listenWhen: (prev, curr) {
        // Detect back navigation from root (list screen with empty stack)
        if (prev is SchemaLoaded && curr is SchemaLoaded) {
          return prev.screenStack.isNotEmpty && curr.screenStack.isEmpty &&
              prev.currentScreen == 'list';
        }
        return false;
      },
      listener: (context, state) {
        onSchemasChanged();
        onPop();
      },
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) {
            onSchemasChanged();
            onPop();
          }
        },
        child: const SchemaNavigator(),
      ),
    );
  }
}
