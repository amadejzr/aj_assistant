import 'package:equatable/equatable.dart';

import 'field_definition.dart';

class ModuleSchema extends Equatable {
  final int version;
  final Map<String, FieldDefinition> fields;

  const ModuleSchema({
    this.version = 1,
    this.fields = const {},
  });

  factory ModuleSchema.fromJson(Map<String, dynamic> json) {
    final fieldsJson = json['fields'] as Map<String, dynamic>? ?? {};
    final fields = fieldsJson.map(
      (key, value) => MapEntry(
        key,
        FieldDefinition.fromJson(key, Map<String, dynamic>.from(value as Map)),
      ),
    );

    return ModuleSchema(
      version: json['version'] as int? ?? 1,
      fields: fields,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'fields': fields.map((key, field) => MapEntry(key, field.toJson())),
    };
  }

  @override
  List<Object?> get props => [version, fields];
}
