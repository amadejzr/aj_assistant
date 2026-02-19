import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../../features/schema/models/field_constraints.dart';
import '../../features/schema/models/module_schema.dart';

class Module extends Equatable {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String color;
  final int sortOrder;
  final Map<String, ModuleSchema> schemas;
  final Map<String, Map<String, dynamic>> screens;
  final Map<String, dynamic> settings;
  final List<Map<String, String>> guide;
  final int version;

  const Module({
    required this.id,
    required this.name,
    this.description = '',
    this.icon = 'cube',
    this.color = '#D94E33',
    this.sortOrder = 0,
    this.schemas = const {'default': ModuleSchema()},
    this.screens = const {},
    this.settings = const {},
    this.guide = const [],
    this.version = 1,
  });

  ModuleSchema get schema => schemas['default'] ?? const ModuleSchema();

  Module copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    String? color,
    int? sortOrder,
    Map<String, ModuleSchema>? schemas,
    Map<String, Map<String, dynamic>>? screens,
    Map<String, dynamic>? settings,
    List<Map<String, String>>? guide,
    int? version,
  }) {
    return Module(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      sortOrder: sortOrder ?? this.sortOrder,
      schemas: schemas ?? this.schemas,
      screens: screens ?? this.screens,
      settings: settings ?? this.settings,
      guide: guide ?? this.guide,
      version: version ?? this.version,
    );
  }

  factory Module.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Module(
      id: doc.id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      icon: data['icon'] as String? ?? 'cube',
      color: data['color'] as String? ?? '#D94E33',
      sortOrder: data['sortOrder'] as int? ?? 0,
      schemas: _parseSchemas(data['schemas']),
      screens: _parseScreens(data['screens']),
      settings: Map<String, dynamic>.from(data['settings'] as Map? ?? {}),
      guide: (data['guide'] as List?)
              ?.cast<Map>()
              .map((m) => Map<String, String>.from(m))
              .toList() ??
          [],
      version: data['version'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'icon': icon,
      'color': color,
      'sortOrder': sortOrder,
      'schemas': schemas.map(
        (key, schema) => MapEntry(key, schema.toJson()),
      ),
      'screens': screens,
      'settings': settings,
      'guide': guide,
      'version': version,
    };
  }

  static Map<String, ModuleSchema> _parseSchemas(dynamic raw) {
    if (raw == null) return const {'default': ModuleSchema()};
    final map = Map<String, dynamic>.from(raw as Map);
    return map.map(
      (key, value) => MapEntry(
        key,
        ModuleSchema.fromJson(Map<String, dynamic>.from(value as Map)),
      ),
    );
  }

  static Map<String, Map<String, dynamic>> _parseScreens(dynamic raw) {
    if (raw == null) return {};
    final map = Map<String, dynamic>.from(raw as Map);
    return map.map(
      (key, value) => MapEntry(
        key,
        Map<String, dynamic>.from(value as Map),
      ),
    );
  }

  /// Computes reverse relations for [schemaKey] by scanning all schemas
  /// for reference fields that point at it.
  List<ReverseRelation> reverseRelationsFor(String schemaKey) {
    final results = <ReverseRelation>[];
    for (final entry in schemas.entries) {
      for (final field in entry.value.fields.values) {
        final c = field.constraints;
        if (c is ReferenceConstraints && c.targetSchema == schemaKey) {
          results.add(ReverseRelation(
            fromSchema: entry.key,
            fromField: field.key,
            label: c.inverseLabel ?? entry.value.label,
          ));
        }
      }
    }
    return results;
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        icon,
        color,
        sortOrder,
        schemas,
        screens,
        settings,
        guide,
        version,
      ];
}

class ReverseRelation extends Equatable {
  final String fromSchema;
  final String fromField;
  final String label;

  const ReverseRelation({
    required this.fromSchema,
    required this.fromField,
    required this.label,
  });

  @override
  List<Object?> get props => [fromSchema, fromField, label];
}
