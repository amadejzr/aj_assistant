import 'package:equatable/equatable.dart';

import 'field_definition.dart';

class ModuleSchema extends Equatable {
  final int version;
  final Map<String, FieldDefinition> fields;
  final String label;
  final String? icon;
  final List<Map<String, dynamic>> effects;

  const ModuleSchema({
    this.version = 1,
    this.fields = const {},
    this.label = '',
    this.icon,
    this.effects = const [],
  });

  ModuleSchema copyWith({
    int? version,
    Map<String, FieldDefinition>? fields,
    String? label,
    String? icon,
    List<Map<String, dynamic>>? effects,
  }) {
    return ModuleSchema(
      version: version ?? this.version,
      fields: fields ?? this.fields,
      label: label ?? this.label,
      icon: icon ?? this.icon,
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

    final effectsRaw = json['effects'] as List?;
    var effects = effectsRaw
            ?.whereType<Map<String, dynamic>>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList() ??
        <Map<String, dynamic>>[];

    // Backward compat: migrate legacy onDelete → effects with inverted ops
    if (effects.isEmpty) {
      final onDeleteRaw = json['onDelete'] as List?;
      if (onDeleteRaw != null && onDeleteRaw.isNotEmpty) {
        effects = onDeleteRaw
            .whereType<Map<String, dynamic>>()
            .map((e) {
              final migrated = Map<String, dynamic>.from(e);
              // Invert the operation since onDelete stored the delete-time op
              final op = migrated['operation'] as String?;
              if (op == 'add') {
                migrated['operation'] = 'subtract';
              } else if (op == 'subtract') {
                migrated['operation'] = 'add';
              }
              return migrated;
            })
            .toList();
      }
    }

    return ModuleSchema(
      version: json['version'] as int? ?? 1,
      fields: fields,
      label: json['label'] as String? ?? '',
      icon: json['icon'] as String?,
      effects: effects,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'fields': fields.map((key, field) => MapEntry(key, field.toJson())),
      'label': label,
      if (icon != null) 'icon': icon,
      if (effects.isNotEmpty) 'effects': effects,
    };
  }

  @override
  List<Object?> get props => [version, fields, label, icon, effects];
}
