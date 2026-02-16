import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/repositories/entry_repository.dart';
import '../../../core/repositories/module_repository.dart';
import '../../../features/auth/bloc/auth_bloc.dart';
import '../../../features/auth/bloc/auth_state.dart';
import '../bloc/module_viewer_bloc.dart';
import '../bloc/module_viewer_event.dart';
import '../bloc/module_viewer_state.dart';
import '../renderer/blueprint_renderer.dart';
import '../renderer/render_context.dart';
import 'field_editor_screen.dart';
import 'module_settings_screen.dart';
import 'schema_editor_screen.dart';

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

    // Route special settings screen IDs
    if (screenId.startsWith('_')) {
      return switch (screenId) {
        '_settings' => const ModuleSettingsScreen(),
        '_schema_editor' => const SchemaEditorScreen(),
        '_field_editor' => const FieldEditorScreen(),
        _ => Scaffold(
            appBar: AppBar(title: const Text('Unknown')),
            body: const Center(child: Text('Unknown settings screen')),
          ),
      };
    }

    final blueprint = state.module.screens[screenId];

    if (blueprint == null) {
      return Scaffold(
        appBar: AppBar(title: Text(state.module.name)),
        body: const Center(child: Text('Screen not found')),
      );
    }

    final renderContext = RenderContext(
      module: state.module,
      entries: state.entries,
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
    );

    return BlueprintRenderer(
      blueprintJson: blueprint,
      context_: renderContext,
    );
  }
}
