import 'package:equatable/equatable.dart';

import '../../../core/models/entry.dart';
import '../../../core/models/field_definition.dart';
import '../../../core/models/module_schema.dart';

sealed class ModuleViewerEvent extends Equatable {
  const ModuleViewerEvent();

  @override
  List<Object?> get props => [];
}

class ModuleViewerStarted extends ModuleViewerEvent {
  final String moduleId;

  const ModuleViewerStarted(this.moduleId);

  @override
  List<Object?> get props => [moduleId];
}

class ModuleViewerScreenChanged extends ModuleViewerEvent {
  final String screenId;
  final Map<String, dynamic> params;

  const ModuleViewerScreenChanged(this.screenId, {this.params = const {}});

  @override
  List<Object?> get props => [screenId, params];
}

class ModuleViewerNavigateBack extends ModuleViewerEvent {
  const ModuleViewerNavigateBack();
}

class ModuleViewerFormValueChanged extends ModuleViewerEvent {
  final String fieldKey;
  final dynamic value;

  const ModuleViewerFormValueChanged(this.fieldKey, this.value);

  @override
  List<Object?> get props => [fieldKey, value];
}

class ModuleViewerFormSubmitted extends ModuleViewerEvent {
  const ModuleViewerFormSubmitted();
}

class ModuleViewerFormReset extends ModuleViewerEvent {
  const ModuleViewerFormReset();
}

class ModuleViewerEntryDeleted extends ModuleViewerEvent {
  final String entryId;

  const ModuleViewerEntryDeleted(this.entryId);

  @override
  List<Object?> get props => [entryId];
}

class ModuleViewerEntriesUpdated extends ModuleViewerEvent {
  final List<Entry> entries;

  const ModuleViewerEntriesUpdated(this.entries);

  @override
  List<Object?> get props => [entries];
}

class ModuleViewerSchemaUpdated extends ModuleViewerEvent {
  final String schemaKey;
  final ModuleSchema schema;

  const ModuleViewerSchemaUpdated(this.schemaKey, this.schema);

  @override
  List<Object?> get props => [schemaKey, schema];
}

class ModuleViewerSchemaAdded extends ModuleViewerEvent {
  final String schemaKey;
  final ModuleSchema schema;

  const ModuleViewerSchemaAdded(this.schemaKey, this.schema);

  @override
  List<Object?> get props => [schemaKey, schema];
}

class ModuleViewerSchemaDeleted extends ModuleViewerEvent {
  final String schemaKey;

  const ModuleViewerSchemaDeleted(this.schemaKey);

  @override
  List<Object?> get props => [schemaKey];
}

class ModuleViewerFieldUpdated extends ModuleViewerEvent {
  final String schemaKey;
  final String fieldKey;
  final FieldDefinition field;

  const ModuleViewerFieldUpdated(this.schemaKey, this.fieldKey, this.field);

  @override
  List<Object?> get props => [schemaKey, fieldKey, field];
}

class ModuleViewerFieldAdded extends ModuleViewerEvent {
  final String schemaKey;
  final String fieldKey;
  final FieldDefinition field;

  const ModuleViewerFieldAdded(this.schemaKey, this.fieldKey, this.field);

  @override
  List<Object?> get props => [schemaKey, fieldKey, field];
}

class ModuleViewerFieldDeleted extends ModuleViewerEvent {
  final String schemaKey;
  final String fieldKey;

  const ModuleViewerFieldDeleted(this.schemaKey, this.fieldKey);

  @override
  List<Object?> get props => [schemaKey, fieldKey];
}

class ModuleViewerQuickEntryCreated extends ModuleViewerEvent {
  final String schemaKey;
  final Map<String, dynamic> data;
  final String? autoSelectFieldKey;

  const ModuleViewerQuickEntryCreated({
    required this.schemaKey,
    required this.data,
    this.autoSelectFieldKey,
  });

  @override
  List<Object?> get props => [schemaKey, data, autoSelectFieldKey];
}

class ModuleViewerQuickEntryUpdated extends ModuleViewerEvent {
  final String entryId;
  final String schemaKey;
  final Map<String, dynamic> data;

  const ModuleViewerQuickEntryUpdated({
    required this.entryId,
    required this.schemaKey,
    required this.data,
  });

  @override
  List<Object?> get props => [entryId, schemaKey, data];
}
