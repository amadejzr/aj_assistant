import 'package:equatable/equatable.dart';

import 'field_definition.dart';

class ModuleSchema extends Equatable {
  final int version;
  final Map<String, FieldDefinition> fields;
  final String label;
  final String? icon;

  const ModuleSchema({
    this.version = 1,
    this.fields = const {},
    this.label = '',
    this.icon,
  });

  ModuleSchema copyWith({
    int? version,
    Map<String, FieldDefinition>? fields,
    String? label,
    String? icon,
  }) {
    return ModuleSchema(
      version: version ?? this.version,
      fields: fields ?? this.fields,
      label: label ?? this.label,
      icon: icon ?? this.icon,
    );
  }

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
      label: json['label'] as String? ?? '',
      icon: json['icon'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'fields': fields.map((key, field) => MapEntry(key, field.toJson())),
      'label': label,
      if (icon != null) 'icon': icon,
    };
  }

  @override
  List<Object?> get props => [version, fields, label, icon];
}
