import 'package:equatable/equatable.dart';

import '../models/field_definition.dart';
import '../models/module_schema.dart';

sealed class SchemaEvent extends Equatable {
  const SchemaEvent();

  @override
  List<Object?> get props => [];
}

class SchemaStarted extends SchemaEvent {
  final String moduleId;

  const SchemaStarted(this.moduleId);

  @override
  List<Object?> get props => [moduleId];
}

class SchemaScreenChanged extends SchemaEvent {
  final String screen;
  final Map<String, dynamic> params;

  const SchemaScreenChanged(this.screen, {this.params = const {}});

  @override
  List<Object?> get props => [screen, params];
}

class SchemaNavigateBack extends SchemaEvent {
  const SchemaNavigateBack();
}

class SchemaUpdated extends SchemaEvent {
  final String schemaKey;
  final ModuleSchema schema;

  const SchemaUpdated(this.schemaKey, this.schema);

  @override
  List<Object?> get props => [schemaKey, schema];
}

class SchemaAdded extends SchemaEvent {
  final String schemaKey;
  final ModuleSchema schema;

  const SchemaAdded(this.schemaKey, this.schema);

  @override
  List<Object?> get props => [schemaKey, schema];
}

class SchemaDeleted extends SchemaEvent {
  final String schemaKey;

  const SchemaDeleted(this.schemaKey);

  @override
  List<Object?> get props => [schemaKey];
}

class FieldUpdated extends SchemaEvent {
  final String schemaKey;
  final String fieldKey;
  final FieldDefinition field;

  const FieldUpdated(this.schemaKey, this.fieldKey, this.field);

  @override
  List<Object?> get props => [schemaKey, fieldKey, field];
}

class FieldAdded extends SchemaEvent {
  final String schemaKey;
  final String fieldKey;
  final FieldDefinition field;

  const FieldAdded(this.schemaKey, this.fieldKey, this.field);

  @override
  List<Object?> get props => [schemaKey, fieldKey, field];
}

class FieldDeleted extends SchemaEvent {
  final String schemaKey;
  final String fieldKey;

  const FieldDeleted(this.schemaKey, this.fieldKey);

  @override
  List<Object?> get props => [schemaKey, fieldKey];
}
