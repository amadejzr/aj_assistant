import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/logging/log.dart';
import '../../../core/models/entry.dart';
import '../../../core/models/module.dart';
import '../../../core/repositories/entry_repository.dart';
import '../../../core/repositories/module_repository.dart';
import '../../blueprint/engine/expression_collector.dart';
import '../../blueprint/engine/expression_evaluator.dart';
import '../../blueprint/engine/post_submit_effect.dart';
import '../../schema/models/schema_effect.dart';
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

      // Subscribe to entries (capped at 500 most recent to limit reads)
      _entriesSub?.cancel();
      _entriesSub = entryRepository
          .watchEntries(userId, event.moduleId, limit: 500)
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

    // Top-level navigation (bottom nav, drawer) resets the stack.
    // Deep navigation (forms, detail screens) pushes onto it.
    final updatedStack = event.clearStack
        ? <ScreenEntry>[]
        : [
            ...current.screenStack,
            ScreenEntry(current.currentScreenId, params: current.screenParams),
          ];

    final resolved = _resolveExpressions(
      current.module,
      event.screenId,
      current.entries,
    );

    emit(current.copyWith(
      currentScreenId: event.screenId,
      screenParams: event.params,
      screenStack: updatedStack,
      formValues: {},
      resolvedExpressions: resolved,
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
      clearSubmitError: current.submitError != null,
    ));
  }

  Future<void> _onFormSubmitted(
    ModuleViewerFormSubmitted event,
    Emitter<ModuleViewerState> emit,
  ) async {
    final current = state;
    if (current is! ModuleViewerLoaded) return;

    emit(current.copyWith(isSubmitting: true, clearSubmitError: true));

    try {
      // Clean form data — remove meta keys (prefixed with _)
      final data = Map<String, dynamic>.from(current.formValues)
        ..removeWhere((key, _) => key.startsWith('_'));

      // Look up effects from the schema (not the screen)
      final schemaKey =
          current.screenParams['_schemaKey'] as String? ?? 'default';
      final schemaEffects =
          current.module.schemas[schemaKey]?.effects ?? const [];

      // Validate effect guards (e.g. min: 0) before creating entry
      if (schemaEffects.isNotEmpty) {
        const executor = PostSubmitEffectExecutor();
        final error = executor.validateEffects(
          effects: schemaEffects,
          formData: data,
          entries: current.entries,
        );
        if (error != null) {
          emit(current.copyWith(
            isSubmitting: false,
            submitError: error,
          ));
          return;
        }
      }

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

      final isCreate = entryId == null || entryId.isEmpty;

      if (!isCreate) {
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

      // Execute effects from schema (only on create, not edit)
      if (isCreate && schemaEffects.isNotEmpty) {
        await _applyPostSubmitEffects(current, schemaEffects, data);
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
      // Look up the entry being deleted to run delete effects (inverted)
      final deletedEntry = current.entries
          .where((e) => e.id == event.entryId)
          .firstOrNull;

      if (deletedEntry != null) {
        final schema = current.module.schemas[deletedEntry.schemaKey];
        if (schema != null && schema.effects.isNotEmpty) {
          await _applyDeleteEffects(current, schema.effects, deletedEntry);
        }
      }

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

  /// Applies delete effects (auto-inverted) using [PostSubmitEffectExecutor].
  Future<void> _applyDeleteEffects(
    ModuleViewerLoaded current,
    List<SchemaEffect> effects,
    Entry deletedEntry,
  ) async {
    const executor = PostSubmitEffectExecutor();
    final updates = executor.computeDeleteUpdates(
      effects: effects,
      deletedEntryData: deletedEntry.data,
      entries: current.entries,
    );

    for (final update in updates.entries) {
      final existing = current.entries
          .where((e) => e.id == update.key)
          .firstOrNull;
      if (existing == null) continue;

      final updatedEntry = Entry(
        id: existing.id,
        data: {...existing.data, ...update.value},
        schemaVersion: existing.schemaVersion,
        schemaKey: existing.schemaKey,
      );

      try {
        await entryRepository.updateEntry(
          userId,
          current.module.id,
          updatedEntry,
        );
      } catch (e) {
        Log.e('Delete effect failed', tag: 'ModuleViewer', error: e);
      }
    }
  }

  void _onEntriesUpdated(
    ModuleViewerEntriesUpdated event,
    Emitter<ModuleViewerState> emit,
  ) {
    final current = state;
    if (current is! ModuleViewerLoaded) return;

    Log.d('Entries updated: ${event.entries.length} entries', tag: 'Perf');

    final resolved = _resolveExpressions(
      current.module,
      current.currentScreenId,
      event.entries,
    );

    emit(current.copyWith(
      entries: event.entries,
      resolvedExpressions: resolved,
    ));
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

  /// Applies post-submit effects using [PostSubmitEffectExecutor].
  Future<void> _applyPostSubmitEffects(
    ModuleViewerLoaded current,
    List<SchemaEffect> effects,
    Map<String, dynamic> formData,
  ) async {
    const executor = PostSubmitEffectExecutor();
    final updates = executor.computeUpdates(
      effects: effects,
      formData: formData,
      entries: current.entries,
    );

    for (final update in updates.entries) {
      final existing = current.entries
          .where((e) => e.id == update.key)
          .firstOrNull;
      if (existing == null) continue;

      final updatedEntry = Entry(
        id: existing.id,
        data: {...existing.data, ...update.value},
        schemaVersion: existing.schemaVersion,
        schemaKey: existing.schemaKey,
      );

      try {
        await entryRepository.updateEntry(
          userId,
          current.module.id,
          updatedEntry,
        );
      } catch (e) {
        Log.e('Post-submit effect failed', tag: 'ModuleViewer', error: e);
      }
    }
  }

  static const _expressionCollector = ExpressionCollector();

  /// Pre-resolves all unfiltered expressions for the given screen so that
  /// individual widget builders can read cached values instead of each
  /// creating their own [ExpressionEvaluator].
  Map<String, dynamic> _resolveExpressions(
    Module module,
    String screenId,
    List<Entry> entries,
  ) {
    final blueprint = module.screens[screenId];
    if (blueprint == null) return const {};

    final expressions = _expressionCollector.collect(blueprint);
    if (expressions.isEmpty) return const {};

    final evaluator = ExpressionEvaluator(
      entries: entries,
      params: module.settings,
    );

    final resolved = <String, dynamic>{};
    for (final expr in expressions) {
      if (expr.startsWith('group(')) {
        resolved[expr] = evaluator.evaluateGroup(expr);
      } else {
        resolved[expr] = evaluator.evaluate(expr);
      }
    }
    Log.d('Resolved ${expressions.length} expressions for screen "$screenId"', tag: 'Perf');
    return resolved;
  }

  @override
  Future<void> close() {
    _entriesSub?.cancel();
    return super.close();
  }
}
