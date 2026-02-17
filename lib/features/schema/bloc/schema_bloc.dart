import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/logging/log.dart';
import '../../../core/repositories/module_repository.dart';
import 'schema_event.dart';
import 'schema_state.dart';

class SchemaBloc extends Bloc<SchemaEvent, SchemaState> {
  final ModuleRepository moduleRepository;
  final String userId;
  final String moduleId;

  SchemaBloc({
    required this.moduleRepository,
    required this.userId,
    required this.moduleId,
  }) : super(const SchemaInitial()) {
    on<SchemaStarted>(_onStarted);
    on<SchemaScreenChanged>(_onScreenChanged);
    on<SchemaNavigateBack>(_onNavigateBack);
    on<SchemaUpdated>(_onSchemaUpdated);
    on<SchemaAdded>(_onSchemaAdded);
    on<SchemaDeleted>(_onSchemaDeleted);
    on<FieldUpdated>(_onFieldUpdated);
    on<FieldAdded>(_onFieldAdded);
    on<FieldDeleted>(_onFieldDeleted);
  }

  Future<void> _onStarted(
    SchemaStarted event,
    Emitter<SchemaState> emit,
  ) async {
    emit(const SchemaLoading());

    try {
      final module = await moduleRepository.getModule(userId, event.moduleId);
      if (module == null) {
        emit(const SchemaError('Module not found'));
        return;
      }

      emit(SchemaLoaded(
        moduleId: module.id,
        schemas: Map.of(module.schemas),
      ));
    } catch (e) {
      Log.e('Failed to load module schemas', tag: 'SchemaBloc', error: e);
      emit(SchemaError('Failed to load schemas: $e'));
    }
  }

  void _onScreenChanged(
    SchemaScreenChanged event,
    Emitter<SchemaState> emit,
  ) {
    final current = state;
    if (current is! SchemaLoaded) return;

    final updatedStack = [
      ...current.screenStack,
      SchemaScreenEntry(current.currentScreen, params: current.screenParams),
    ];

    emit(current.copyWith(
      currentScreen: event.screen,
      screenParams: event.params,
      screenStack: updatedStack,
    ));
  }

  void _onNavigateBack(
    SchemaNavigateBack event,
    Emitter<SchemaState> emit,
  ) {
    final current = state;
    if (current is! SchemaLoaded) return;
    if (current.screenStack.isEmpty) return;

    final stack = List<SchemaScreenEntry>.from(current.screenStack);
    final previous = stack.removeLast();

    emit(current.copyWith(
      currentScreen: previous.screen,
      screenParams: previous.params,
      screenStack: stack,
    ));
  }

  Future<void> _onSchemaUpdated(
    SchemaUpdated event,
    Emitter<SchemaState> emit,
  ) async {
    final current = state;
    if (current is! SchemaLoaded) return;
    if (!current.schemas.containsKey(event.schemaKey)) return;

    final schemas = Map.of(current.schemas);
    schemas[event.schemaKey] = event.schema;

    await _persistSchemas(current.moduleId, schemas);
    emit(current.copyWith(schemas: schemas));
  }

  Future<void> _onSchemaAdded(
    SchemaAdded event,
    Emitter<SchemaState> emit,
  ) async {
    final current = state;
    if (current is! SchemaLoaded) return;

    final schemas = Map.of(current.schemas);
    schemas[event.schemaKey] = event.schema;

    await _persistSchemas(current.moduleId, schemas);
    emit(current.copyWith(schemas: schemas));
  }

  Future<void> _onSchemaDeleted(
    SchemaDeleted event,
    Emitter<SchemaState> emit,
  ) async {
    final current = state;
    if (current is! SchemaLoaded) return;

    final schemas = Map.of(current.schemas);
    schemas.remove(event.schemaKey);

    await _persistSchemas(current.moduleId, schemas);
    emit(current.copyWith(schemas: schemas));
  }

  Future<void> _onFieldUpdated(
    FieldUpdated event,
    Emitter<SchemaState> emit,
  ) async {
    final current = state;
    if (current is! SchemaLoaded) return;
    final schema = current.schemas[event.schemaKey];
    if (schema == null) return;

    final fields = Map.of(schema.fields);
    fields[event.fieldKey] = event.field;
    final updatedSchema = schema.copyWith(fields: fields);
    final schemas = Map.of(current.schemas);
    schemas[event.schemaKey] = updatedSchema;

    await _persistSchemas(current.moduleId, schemas);
    emit(current.copyWith(schemas: schemas));
  }

  Future<void> _onFieldAdded(
    FieldAdded event,
    Emitter<SchemaState> emit,
  ) async {
    final current = state;
    if (current is! SchemaLoaded) return;
    final schema = current.schemas[event.schemaKey];
    if (schema == null) return;

    final fields = Map.of(schema.fields);
    fields[event.fieldKey] = event.field;
    final updatedSchema = schema.copyWith(fields: fields);
    final schemas = Map.of(current.schemas);
    schemas[event.schemaKey] = updatedSchema;

    await _persistSchemas(current.moduleId, schemas);
    emit(current.copyWith(schemas: schemas));
  }

  Future<void> _onFieldDeleted(
    FieldDeleted event,
    Emitter<SchemaState> emit,
  ) async {
    final current = state;
    if (current is! SchemaLoaded) return;
    final schema = current.schemas[event.schemaKey];
    if (schema == null) return;

    final fields = Map.of(schema.fields);
    fields.remove(event.fieldKey);
    final updatedSchema = schema.copyWith(fields: fields);
    final schemas = Map.of(current.schemas);
    schemas[event.schemaKey] = updatedSchema;

    await _persistSchemas(current.moduleId, schemas);
    emit(current.copyWith(schemas: schemas));
  }

  Future<void> _persistSchemas(
    String moduleId,
    Map<String, dynamic> schemas,
  ) async {
    try {
      final module = await moduleRepository.getModule(userId, moduleId);
      if (module == null) return;
      final updatedModule = module.copyWith(schemas: Map.castFrom(schemas));
      await moduleRepository.updateModule(userId, updatedModule);
    } catch (e) {
      Log.e('Failed to persist schemas', tag: 'SchemaBloc', error: e);
    }
  }
}
