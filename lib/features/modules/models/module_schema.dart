import 'package:equatable/equatable.dart';

import 'field_definition.dart';
import 'schema_effect.dart';

class ModuleSchema extends Equatable {
  final int version;
  final Map<String, FieldDefinition> fields;
  final String label;
  final String? icon;
  final String? displayField;
  final List<SchemaEffect> effects;

  const ModuleSchema({
    this.version = 1,
    this.fields = const {},
    this.label = '',
    this.icon,
    this.displayField,
    this.effects = const [],
  });

  ModuleSchema copyWith({
    int? version,
    Map<String, FieldDefinition>? fields,
    String? label,
    String? icon,
    String? displayField,
    List<SchemaEffect>? effects,
  }) {
    return ModuleSchema(
      version: version ?? this.version,
      fields: fields ?? this.fields,
      label: label ?? this.label,
      icon: icon ?? this.icon,
      displayField: displayField ?? this.displayField,
      effects: effects ?? this.effects,
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

    // Parse typed effects
    final effectsRaw = json['effects'] as List?;
    var effects = effectsRaw
            ?.whereType<Map>()
            .map((e) => SchemaEffect.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        <SchemaEffect>[];

    // Backward compat: migrate legacy onDelete → effects with inverted ops
    if (effects.isEmpty) {
      final onDeleteRaw = json['onDelete'] as List?;
      if (onDeleteRaw != null && onDeleteRaw.isNotEmpty) {
        effects = onDeleteRaw.whereType<Map>().map((e) {
          final map = Map<String, dynamic>.from(e);
          // Invert the operation since onDelete stored the delete-time op
          final op = map['operation'] as String?;
          if (op == 'add') {
            map['operation'] = 'subtract';
          } else if (op == 'subtract') {
            map['operation'] = 'add';
          }
          return SchemaEffect.fromJson(map);
        }).toList();
      }
    }

    return ModuleSchema(
      version: json['version'] as int? ?? 1,
      fields: fields,
      label: json['label'] as String? ?? '',
      icon: json['icon'] as String?,
      displayField: json['displayField'] as String?,
      effects: effects,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'fields': fields.map((key, field) => MapEntry(key, field.toJson())),
      'label': label,
      if (icon != null) 'icon': icon,
      if (displayField != null) 'displayField': displayField,
      if (effects.isNotEmpty)
        'effects': effects.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [version, fields, label, icon, displayField, effects];
}
