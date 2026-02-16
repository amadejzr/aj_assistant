import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import 'module_schema.dart';

class Module extends Equatable {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String color;
  final int sortOrder;
  final ModuleSchema schema;
  final Map<String, Map<String, dynamic>> screens;
  final Map<String, dynamic> settings;

  const Module({
    required this.id,
    required this.name,
    this.description = '',
    this.icon = 'cube',
    this.color = '#D94E33',
    this.sortOrder = 0,
    this.schema = const ModuleSchema(),
    this.screens = const {},
    this.settings = const {},
  });

  factory Module.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Module(
      id: doc.id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      icon: data['icon'] as String? ?? 'cube',
      color: data['color'] as String? ?? '#D94E33',
      sortOrder: data['sortOrder'] as int? ?? 0,
      schema: ModuleSchema.fromJson(
        Map<String, dynamic>.from(data['schema'] as Map? ?? {}),
      ),
      screens: _parseScreens(data['screens']),
      settings: Map<String, dynamic>.from(data['settings'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'icon': icon,
      'color': color,
      'sortOrder': sortOrder,
      'schema': schema.toJson(),
      'screens': screens,
      'settings': settings,
    };
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

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        icon,
        color,
        sortOrder,
        schema,
        screens,
        settings,
      ];
}
