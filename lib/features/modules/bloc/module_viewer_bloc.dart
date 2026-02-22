import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/mutation_executor.dart';
import '../../../core/database/param_resolver.dart';
import '../../../core/database/query_executor.dart';
import '../../../core/database/schema_manager.dart';
import '../../../core/database/screen_query.dart';
import '../../../core/logging/log.dart';
import '../../../core/models/module.dart';
import '../../../core/repositories/module_repository.dart';
import '../../blueprint/engine/expression_collector.dart';
import '../../blueprint/engine/expression_evaluator.dart';
import '../../capabilities/models/capability.dart';
import '../../capabilities/repositories/capability_repository.dart';
import '../../capabilities/services/notification_scheduler.dart';
import 'module_viewer_event.dart';
import 'module_viewer_state.dart';

class ModuleViewerBloc extends Bloc<ModuleViewerEvent, ModuleViewerState> {
  final ModuleRepository moduleRepository;
  final AppDatabase? appDatabase;
  final String userId;
  final CapabilityRepository? capabilityRepository;
  final NotificationScheduler? notificationScheduler;

  // SQL-driven screen state
  QueryExecutor? _queryExecutor;
  MutationExecutor? _mutationExecutor;
  StreamSubscription<QueryWatchResult>? _querySub;
  List<ScreenQuery> _currentQueries = [];
  ScreenMutations? _currentMutations;

  ModuleViewerBloc({
    required this.moduleRepository,
    this.appDatabase,
    required this.userId,
    this.capabilityRepository,
    this.notificationScheduler,
  }) : super(const ModuleViewerInitial()) {
    on<ModuleViewerStarted>(_onStarted);
    on<ModuleViewerScreenChanged>(_onScreenChanged);
    on<ModuleViewerNavigateBack>(_onNavigateBack);
    on<ModuleViewerFormValueChanged>(_onFormValueChanged);
    on<ModuleViewerFormSubmitted>(_onFormSubmitted);
    on<ModuleViewerFormReset>(_onFormReset);
    on<ModuleViewerEntryDeleted>(_onEntryDeleted);
    on<ModuleViewerModuleRefreshed>(_onModuleRefreshed);
    on<ModuleViewerScreenParamChanged>(_onScreenParamChanged);
    on<ModuleViewerQueryResultsUpdated>(_onQueryResultsUpdated);
    on<ModuleViewerFormPrePopulated>(_onFormPrePopulated);
    on<ModuleViewerLoadNextPage>(_onLoadNextPage);
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

      if (module.database != null && appDatabase != null) {
        // SQL-driven path
        await SchemaManager(db: appDatabase!).installModule(module);
        final tableNames = module.database!.tableNames.values.toSet();
        _queryExecutor = QueryExecutor(
          db: appDatabase!,
          moduleTableNames: tableNames,
        );
        _mutationExecutor = MutationExecutor(
          db: appDatabase!,
          moduleTableNames: tableNames,
        );
        _subscribeToScreen(module, 'main', const {});
      }
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

    final resolved = _resolveExpressions(current.module, event.screenId);

    emit(current.copyWith(
      currentScreenId: event.screenId,
      screenParams: event.params,
      screenStack: updatedStack,
      formValues: {},
      resolvedExpressions: resolved,
    ));

    if (_queryExecutor != null) {
      _subscribeToScreen(current.module, event.screenId, event.params);
    }
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

    // Re-run queries that depend on this field
    _rerunDependentQueries(event.fieldKey, updated, current.screenParams);
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

      // SQL mutation path
      if (_mutationExecutor != null && _currentMutations != null) {
        final ScreenMutation mutation;
        if (entryId != null && entryId.isNotEmpty) {
          mutation = _currentMutations!.update!;
          await _mutationExecutor!.update(mutation, entryId, data);
        } else {
          mutation = _currentMutations!.create!;
          await _mutationExecutor!.create(mutation, data);
        }

        await _processReminderSideEffects(
          mutation,
          current.formValues,
          current.screenParams,
          current.module.id,
        );

        final successMessage = mutation.onSuccess?['message'] as String?;

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
          submitSuccess: successMessage,
        ));

        // Re-subscribe to the previous screen's queries
        _subscribeToScreen(current.module, previous.screenId, previous.params);
        return;
      }

    } catch (e) {
      Log.e('Failed to save entry', tag: 'ModuleViewer', error: e);

      // Use mutation-specific error message if available
      final errorMessage = _getMutationErrorMessage(e, current);
      emit(current.copyWith(
        isSubmitting: false,
        submitError: errorMessage,
      ));
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
      // SQL delete path
      if (_mutationExecutor != null && _currentMutations?.delete != null) {
        final mutation = _currentMutations!.delete!;
        await _mutationExecutor!.delete(mutation, event.entryId);

        final successMessage = mutation.onSuccess?['message'] as String?;

        // Navigate back if on detail screen for this entry
        final currentEntryId = current.screenParams['_entryId'] as String?;
        if (currentEntryId == event.entryId &&
            current.screenStack.isNotEmpty) {
          final stack = List<ScreenEntry>.from(current.screenStack);
          final previous = stack.removeLast();
          emit(current.copyWith(
            currentScreenId: previous.screenId,
            screenParams: previous.params,
            screenStack: stack,
            formValues: {},
            submitSuccess: successMessage,
          ));
        } else if (successMessage != null) {
          emit(current.copyWith(submitSuccess: successMessage));
        }
        return;
      }

    } catch (e) {
      Log.e('Failed to delete entry', tag: 'ModuleViewer', error: e);
      final errorMessage =
          _currentMutations?.delete?.onError?['message'] as String? ??
              e.toString();
      emit(current.copyWith(submitError: errorMessage));
    }
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

    if (_queryExecutor != null) {
      _subscribeToScreen(current.module, current.currentScreenId, updated);
    }
  }

  // ─── SQL-driven screen subscription ───

  void _subscribeToScreen(
    Module module,
    String screenId,
    Map<String, dynamic> screenParams,
  ) {
    _querySub?.cancel();
    final screenJson = module.screens[screenId];
    if (screenJson == null) return;

    _currentQueries = parseScreenQueries(screenJson);
    final mutationsJson = screenJson['mutations'] as Map<String, dynamic>?;
    _currentMutations = mutationsJson != null
        ? ScreenMutations.fromJson(mutationsJson)
        : null;

    if (_currentQueries.isNotEmpty) {
      final resolvedParams = resolveQueryParams(_currentQueries, screenParams);
      _querySub = _queryExecutor!
          .watchAll(_currentQueries, resolvedParams)
          .listen((result) => add(ModuleViewerQueryResultsUpdated(
                result.results,
                errors: result.errors,
              )));
    }

    // Pre-populate form for edit mode
    _prePopulateForm(module, screenParams);
  }

  Future<void> _prePopulateForm(
    Module module,
    Map<String, dynamic> screenParams,
  ) async {
    final entryId = screenParams['_entryId'] as String?;
    if (entryId == null || _queryExecutor == null) return;

    final schemaKey = screenParams['_schemaKey'] as String? ?? 'default';
    final tableName = module.database?.tableNames[schemaKey];
    if (tableName == null) return;

    try {
      final rows = await _queryExecutor!.execute(
        ScreenQuery(
          name: '_lookup',
          sql: 'SELECT * FROM "$tableName" WHERE id = :id',
        ),
        {'id': entryId},
      );
      if (rows.isNotEmpty) {
        add(ModuleViewerFormPrePopulated(rows.first));
      }
    } catch (e) {
      Log.e('Failed to pre-populate form', tag: 'ModuleViewer', error: e);
    }
  }

  void _onQueryResultsUpdated(
    ModuleViewerQueryResultsUpdated event,
    Emitter<ModuleViewerState> emit,
  ) {
    final current = state;
    if (current is! ModuleViewerLoaded) return;

    emit(current.copyWith(
      queryResults: event.results,
      queryErrors: event.errors,
    ));
  }

  Future<void> _onLoadNextPage(
    ModuleViewerLoadNextPage event,
    Emitter<ModuleViewerState> emit,
  ) async {
    final current = state;
    if (current is! ModuleViewerLoaded) return;
    if (_queryExecutor == null) return;

    final query = _currentQueries.cast<ScreenQuery?>().firstWhere(
          (q) => q!.name == event.queryName,
          orElse: () => null,
        );
    if (query == null) return;

    // Get the page size from the screen JSON
    final screenJson = current.module.screens[current.currentScreenId];
    final pageSize = _findPageSizeForQuery(screenJson, event.queryName) ?? 20;

    final offsets = Map<String, int>.from(current.paginationOffsets);
    final currentOffset = offsets[event.queryName] ?? pageSize;
    final newOffset = currentOffset + pageSize;
    offsets[event.queryName] = newOffset;

    try {
      final resolvedParams = resolveQueryParams(
        [query],
        current.screenParams,
        formValues: current.formValues,
      );
      final newRows = await _queryExecutor!.executePaginated(
        query,
        resolvedParams,
        limit: pageSize,
        offset: currentOffset,
      );

      final updatedResults = Map<String, List<Map<String, dynamic>>>.from(
        current.queryResults,
      );
      final existing = updatedResults[event.queryName] ?? [];
      updatedResults[event.queryName] = [...existing, ...newRows];

      emit(current.copyWith(
        queryResults: updatedResults,
        paginationOffsets: offsets,
      ));
    } catch (e) {
      Log.e('Failed to load next page', tag: 'ModuleViewer', error: e);
    }
  }

  int? _findPageSizeForQuery(Map<String, dynamic>? screenJson, String queryName) {
    if (screenJson == null) return null;
    final children = screenJson['children'] as List?;
    if (children == null) return null;
    for (final child in children) {
      if (child is Map<String, dynamic>) {
        if (child['type'] == 'entry_list' && child['source'] == queryName) {
          return child['pageSize'] as int?;
        }
        // Recurse into children
        final nested = _findPageSizeForQuery(child, queryName);
        if (nested != null) return nested;
      }
    }
    return null;
  }

  void _onFormPrePopulated(
    ModuleViewerFormPrePopulated event,
    Emitter<ModuleViewerState> emit,
  ) {
    final current = state;
    if (current is! ModuleViewerLoaded) return;

    emit(current.copyWith(formValues: event.values));
  }

  /// Re-runs queries whose `dependsOn` list contains the changed field.
  void _rerunDependentQueries(
    String changedField,
    Map<String, dynamic> formValues,
    Map<String, dynamic> screenParams,
  ) {
    if (_queryExecutor == null) return;

    final dependentQueries = _currentQueries
        .where((q) => q.dependsOn.contains(changedField))
        .toList();

    if (dependentQueries.isEmpty) return;

    final resolvedParams = resolveQueryParams(
      dependentQueries,
      screenParams,
      formValues: formValues,
    );

    for (final query in dependentQueries) {
      _queryExecutor!.execute(query, resolvedParams).then((rows) {
        final current = state;
        if (current is! ModuleViewerLoaded) return;
        final updated = Map<String, List<Map<String, dynamic>>>.from(
          current.queryResults,
        );
        updated[query.name] = rows;
        add(ModuleViewerQueryResultsUpdated(updated));
      });
    }
  }

  String _getMutationErrorMessage(Object error, ModuleViewerLoaded current) {
    final entryId = current.screenParams['_entryId'] as String?;
    final ScreenMutation? mutation;
    if (entryId != null && entryId.isNotEmpty) {
      mutation = _currentMutations?.update;
    } else {
      mutation = _currentMutations?.create;
    }
    return mutation?.onError?['message'] as String? ?? error.toString();
  }

  static const _expressionCollector = ExpressionCollector();

  /// Pre-resolves all unfiltered expressions for the given screen so that
  /// individual widget builders can read cached values instead of each
  /// creating their own [ExpressionEvaluator].
  Map<String, dynamic> _resolveExpressions(
    Module module,
    String screenId,
  ) {
    final blueprint = module.screens[screenId];
    if (blueprint == null) return const {};

    final expressions = _expressionCollector.collect(blueprint);
    if (expressions.isEmpty) return const {};

    final evaluator = ExpressionEvaluator(
      entries: const [],
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

  // ─── Reminder side-effects ───

  Future<void> _processReminderSideEffects(
    ScreenMutation mutation,
    Map<String, dynamic> formValues,
    Map<String, dynamic> screenParams,
    String moduleId,
  ) async {
    if (mutation.reminders.isEmpty) return;
    if (capabilityRepository == null) return;

    final data = {...screenParams, ...formValues};

    for (final reminder in mutation.reminders) {
      if (reminder.conditionField != null) {
        final conditionValue = data[reminder.conditionField];
        if (conditionValue == null || conditionValue == false) continue;
      }

      final dateValue = data[reminder.dateField];
      if (dateValue == null) continue;

      final title = _resolveTemplate(reminder.titleField, data);
      final message = _resolveTemplate(reminder.messageField, data);

      final scheduledDate = dateValue is int
          ? DateTime.fromMillisecondsSinceEpoch(dateValue)
          : DateTime.tryParse(dateValue.toString());
      if (scheduledDate == null) continue;

      var hour = reminder.hour;
      var minute = reminder.minute;
      if (reminder.timeField != null) {
        final timeValue = data[reminder.timeField];
        if (timeValue is Map) {
          hour = timeValue['hour'] as int? ?? hour;
          minute = timeValue['minute'] as int? ?? minute;
        } else if (timeValue is int) {
          hour = timeValue ~/ 60;
          minute = timeValue % 60;
        }
      }

      final now = DateTime.now();
      final capability = ScheduledReminder(
        id: '${moduleId}_reminder_${now.millisecondsSinceEpoch}',
        moduleId: moduleId,
        title: title,
        message: message,
        enabled: true,
        createdAt: now,
        updatedAt: now,
        frequency: ReminderFrequency.once,
        hour: hour,
        minute: minute,
        scheduledDate: scheduledDate,
      );

      await capabilityRepository!.createCapability(capability);
      await notificationScheduler?.scheduleCapability(capability);
    }
  }

  String _resolveTemplate(String template, Map<String, dynamic> data) {
    if (template.contains('{{')) {
      return template.replaceAllMapped(
        RegExp(r'\{\{([\w.]+)\}\}'),
        (match) => data[match.group(1)!]?.toString() ?? '',
      );
    }
    return data[template]?.toString() ?? template;
  }

  @override
  Future<void> close() {
    _querySub?.cancel();
    return super.close();
  }
}
