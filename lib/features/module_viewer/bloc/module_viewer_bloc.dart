import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/logging/log.dart';
import '../../../core/models/entry.dart';
import '../../../core/repositories/entry_repository.dart';
import '../../../core/repositories/module_repository.dart';
import 'module_viewer_event.dart';
import 'module_viewer_state.dart';

class ModuleViewerBloc extends Bloc<ModuleViewerEvent, ModuleViewerState> {
  final ModuleRepository moduleRepository;
  final EntryRepository entryRepository;
  final String userId;

  StreamSubscription<List<Entry>>? _entriesSub;

  ModuleViewerBloc({
    required this.moduleRepository,
    required this.entryRepository,
    required this.userId,
  }) : super(const ModuleViewerInitial()) {
    on<ModuleViewerStarted>(_onStarted);
    on<ModuleViewerScreenChanged>(_onScreenChanged);
    on<ModuleViewerNavigateBack>(_onNavigateBack);
    on<ModuleViewerFormValueChanged>(_onFormValueChanged);
    on<ModuleViewerFormSubmitted>(_onFormSubmitted);
    on<ModuleViewerFormReset>(_onFormReset);
    on<ModuleViewerEntryDeleted>(_onEntryDeleted);
    on<ModuleViewerEntriesUpdated>(_onEntriesUpdated);
    on<ModuleViewerModuleRefreshed>(_onModuleRefreshed);
    on<ModuleViewerScreenParamChanged>(_onScreenParamChanged);
    on<ModuleViewerQuickEntryCreated>(_onQuickEntryCreated);
    on<ModuleViewerQuickEntryUpdated>(_onQuickEntryUpdated);
  }

  Future<void> _onStarted(
    ModuleViewerStarted event,
    Emitter<ModuleViewerState> emit,
  ) async {
    emit(const ModuleViewerLoading());

    try {
      final module = await moduleRepository.getModule(userId, event.moduleId);
      if (module == null) {
        emit(const ModuleViewerError('Module not found'));
        return;
      }

      emit(ModuleViewerLoaded(module: module));

      // Subscribe to entries
      _entriesSub?.cancel();
      _entriesSub = entryRepository
          .watchEntries(userId, event.moduleId)
          .listen(
            (entries) => add(ModuleViewerEntriesUpdated(entries)),
            onError: (e) => Log.e('Entries stream error', tag: 'ModuleViewer', error: e),
          );
    } catch (e) {
      Log.e('Failed to load module', tag: 'ModuleViewer', error: e);
      emit(ModuleViewerError('Failed to load module: $e'));
    }
  }

  void _onScreenChanged(
    ModuleViewerScreenChanged event,
    Emitter<ModuleViewerState> emit,
  ) {
    final current = state;
    if (current is! ModuleViewerLoaded) return;

    // Push current screen onto the stack before navigating
    final updatedStack = [
      ...current.screenStack,
      ScreenEntry(current.currentScreenId, params: current.screenParams),
    ];

    emit(current.copyWith(
      currentScreenId: event.screenId,
      screenParams: event.params,
      screenStack: updatedStack,
      formValues: {},
    ));
  }

  void _onNavigateBack(
    ModuleViewerNavigateBack event,
    Emitter<ModuleViewerState> emit,
  ) {
    final current = state;
    if (current is! ModuleViewerLoaded) return;
    if (current.screenStack.isEmpty) return;

    final stack = List<ScreenEntry>.from(current.screenStack);
    final previous = stack.removeLast();

    emit(current.copyWith(
      currentScreenId: previous.screenId,
      screenParams: previous.params,
      screenStack: stack,
      formValues: {},
    ));
  }

  void _onFormValueChanged(
    ModuleViewerFormValueChanged event,
    Emitter<ModuleViewerState> emit,
  ) {
    final current = state;
    if (current is! ModuleViewerLoaded) return;

    final updated = Map<String, dynamic>.from(current.formValues);
    updated[event.fieldKey] = event.value;

    // Clear pendingAutoSelect if this change satisfies it
    final pending = current.pendingAutoSelect;
    final shouldClear =
        pending != null && pending.fieldKey == event.fieldKey;

    emit(current.copyWith(
      formValues: updated,
      clearPendingAutoSelect: shouldClear,
    ));
  }

  Future<void> _onFormSubmitted(
    ModuleViewerFormSubmitted event,
    Emitter<ModuleViewerState> emit,
  ) async {
    final current = state;
    if (current is! ModuleViewerLoaded) return;

    emit(current.copyWith(isSubmitting: true));

    try {
      // Clean form data — remove meta keys (prefixed with _)
      final data = Map<String, dynamic>.from(current.formValues)
        ..removeWhere((key, _) => key.startsWith('_'));

      // Settings mode — update module settings instead of entries
      if (current.screenParams['_settingsMode'] == true) {
        final updatedSettings = {
          ...current.module.settings,
          ...data,
        };
        final updatedModule = current.module.copyWith(settings: updatedSettings);
        await moduleRepository.updateModule(userId, updatedModule);

        final stack = List<ScreenEntry>.from(current.screenStack);
        final previous = stack.isNotEmpty
            ? stack.removeLast()
            : const ScreenEntry('main');

        emit(current.copyWith(
          module: updatedModule,
          currentScreenId: previous.screenId,
          screenParams: previous.params,
          screenStack: stack,
          formValues: {},
          isSubmitting: false,
        ));
        return;
      }

      final entryId = current.screenParams['_entryId'] as String?;
      final schemaKey =
          current.screenParams['_schemaKey'] as String? ?? 'default';

      if (entryId != null && entryId.isNotEmpty) {
        // Update existing entry — merge new form values into existing data
        final existing = current.entries
            .where((e) => e.id == entryId)
            .firstOrNull;
        final mergedData = {
          if (existing != null) ...existing.data,
          ...data,
        };
        final updated = Entry(
          id: entryId,
          data: mergedData,
          schemaVersion: current.module.schema.version,
          schemaKey: existing?.schemaKey ?? schemaKey,
        );
        await entryRepository.updateEntry(userId, current.module.id, updated);
      } else {
        // Create new entry
        final entry = Entry(
          id: '',
          data: data,
          schemaVersion: current.module.schema.version,
          schemaKey: schemaKey,
        );
        await entryRepository.createEntry(userId, current.module.id, entry);
      }

      // Navigate back to previous screen (or main)
      final stack = List<ScreenEntry>.from(current.screenStack);
      final previous = stack.isNotEmpty
          ? stack.removeLast()
          : const ScreenEntry('main');

      emit(current.copyWith(
        currentScreenId: previous.screenId,
        screenParams: previous.params,
        screenStack: stack,
        formValues: {},
        isSubmitting: false,
      ));
    } catch (e) {
      Log.e('Failed to save entry', tag: 'ModuleViewer', error: e);
      emit(current.copyWith(isSubmitting: false));
    }
  }

  void _onFormReset(
    ModuleViewerFormReset event,
    Emitter<ModuleViewerState> emit,
  ) {
    final current = state;
    if (current is! ModuleViewerLoaded) return;

    emit(current.copyWith(formValues: {}));
  }

  Future<void> _onEntryDeleted(
    ModuleViewerEntryDeleted event,
    Emitter<ModuleViewerState> emit,
  ) async {
    final current = state;
    if (current is! ModuleViewerLoaded) return;

    try {
      await entryRepository.deleteEntry(userId, current.module.id, event.entryId);

      // If we're on a detail screen for this entry, navigate back
      final currentEntryId = current.screenParams['_entryId'] as String?;
      if (currentEntryId == event.entryId && current.screenStack.isNotEmpty) {
        final stack = List<ScreenEntry>.from(current.screenStack);
        final previous = stack.removeLast();
        emit(current.copyWith(
          currentScreenId: previous.screenId,
          screenParams: previous.params,
          screenStack: stack,
          formValues: {},
        ));
      }
    } catch (e) {
      Log.e('Failed to delete entry', tag: 'ModuleViewer', error: e);
    }
  }

  void _onEntriesUpdated(
    ModuleViewerEntriesUpdated event,
    Emitter<ModuleViewerState> emit,
  ) {
    final current = state;
    if (current is! ModuleViewerLoaded) return;

    emit(current.copyWith(entries: event.entries));
  }

  Future<void> _onModuleRefreshed(
    ModuleViewerModuleRefreshed event,
    Emitter<ModuleViewerState> emit,
  ) async {
    final current = state;
    if (current is! ModuleViewerLoaded) return;

    try {
      final module = await moduleRepository.getModule(userId, current.module.id);
      if (module == null) return;
      emit(current.copyWith(module: module));
    } catch (e) {
      Log.e('Failed to refresh module', tag: 'ModuleViewer', error: e);
    }
  }

  void _onScreenParamChanged(
    ModuleViewerScreenParamChanged event,
    Emitter<ModuleViewerState> emit,
  ) {
    final current = state;
    if (current is! ModuleViewerLoaded) return;

    final updated = Map<String, dynamic>.from(current.screenParams);
    updated[event.key] = event.value;

    emit(current.copyWith(screenParams: updated));
  }

  Future<void> _onQuickEntryCreated(
    ModuleViewerQuickEntryCreated event,
    Emitter<ModuleViewerState> emit,
  ) async {
    final current = state;
    if (current is! ModuleViewerLoaded) return;

    try {
      final entry = Entry(
        id: '',
        data: event.data,
        schemaVersion:
            current.module.schemas[event.schemaKey]?.version ?? 1,
        schemaKey: event.schemaKey,
      );
      final newId = await entryRepository.createEntry(
        userId,
        current.module.id,
        entry,
      );

      if (event.autoSelectFieldKey != null) {
        emit(current.copyWith(
          pendingAutoSelect: (
            fieldKey: event.autoSelectFieldKey!,
            entryId: newId,
          ),
        ));
      }
    } catch (e) {
      Log.e('Failed to create quick entry', tag: 'ModuleViewer', error: e);
    }
  }

  Future<void> _onQuickEntryUpdated(
    ModuleViewerQuickEntryUpdated event,
    Emitter<ModuleViewerState> emit,
  ) async {
    final current = state;
    if (current is! ModuleViewerLoaded) return;

    try {
      final existing = current.entries
          .where((e) => e.id == event.entryId)
          .firstOrNull;
      final mergedData = {
        if (existing != null) ...existing.data,
        ...event.data,
      };
      final updated = Entry(
        id: event.entryId,
        data: mergedData,
        schemaVersion:
            current.module.schemas[event.schemaKey]?.version ?? 1,
        schemaKey: event.schemaKey,
      );
      await entryRepository.updateEntry(userId, current.module.id, updated);
    } catch (e) {
      Log.e('Failed to update quick entry', tag: 'ModuleViewer', error: e);
    }
  }

  @override
  Future<void> close() {
    _entriesSub?.cancel();
    return super.close();
  }
}
