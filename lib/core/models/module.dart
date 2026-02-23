import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../../features/blueprint/navigation/module_navigation.dart';
import '../database/module_database.dart';

class Module extends Equatable {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String color;
  final int sortOrder;
  final Map<String, Map<String, dynamic>> screens;
  final Map<String, dynamic> settings;
  final List<Map<String, String>> guide;
  final int version;
  final ModuleNavigation? navigation;
  final ModuleDatabase? database;
  final Map<String, List<Map<String, dynamic>>> fieldSets;

  /// Reads declared capabilities from `settings['capabilities']`.
  List<Map<String, dynamic>> get capabilities =>
      (settings['capabilities'] as List?)
          ?.cast<Map<String, dynamic>>() ??
          const [];

  /// Per-capability enabled/disabled overrides set by the user.
  Map<String, bool> get capabilityStates =>
      (settings['capabilityStates'] as Map?)?.cast<String, bool>() ?? const {};

  /// Whether a given capability type is enabled (defaults to `true`).
  bool isCapabilityEnabled(String type) => capabilityStates[type] ?? true;

  const Module({
    required this.id,
    required this.name,
    this.description = '',
    this.icon = 'cube',
    this.color = '#D94E33',
    this.sortOrder = 0,
    this.screens = const {},
    this.settings = const {},
    this.guide = const [],
    this.version = 1,
    this.navigation,
    this.database,
    this.fieldSets = const {},
  });

  Module copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    String? color,
    int? sortOrder,
    Map<String, Map<String, dynamic>>? screens,
    Map<String, dynamic>? settings,
    List<Map<String, String>>? guide,
    int? version,
    ModuleNavigation? navigation,
    ModuleDatabase? database,
    Map<String, List<Map<String, dynamic>>>? fieldSets,
  }) {
    return Module(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      sortOrder: sortOrder ?? this.sortOrder,
      screens: screens ?? this.screens,
      settings: settings ?? this.settings,
      guide: guide ?? this.guide,
      version: version ?? this.version,
      navigation: navigation ?? this.navigation,
      database: database ?? this.database,
      fieldSets: fieldSets ?? this.fieldSets,
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
      screens: _parseScreens(data['screens']),
      settings: Map<String, dynamic>.from(data['settings'] as Map? ?? {}),
      guide: (data['guide'] as List?)
              ?.cast<Map>()
              .map((m) => Map<String, String>.from(m))
              .toList() ??
          [],
      version: data['version'] as int? ?? 1,
      navigation: data['navigation'] != null
          ? ModuleNavigation.fromJson(
              Map<String, dynamic>.from(data['navigation'] as Map))
          : null,
      database: data['database'] != null
          ? ModuleDatabase.fromJson(
              Map<String, dynamic>.from(data['database'] as Map))
          : null,
      fieldSets: _parseFieldSets(data['fieldSets']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'icon': icon,
      'color': color,
      'sortOrder': sortOrder,
      'screens': screens,
      'settings': settings,
      'guide': guide,
      'version': version,
      if (navigation != null) 'navigation': navigation!.toJson(),
      if (database != null) 'database': database!.toJson(),
      if (fieldSets.isNotEmpty) 'fieldSets': fieldSets,
    };
  }

  static Map<String, List<Map<String, dynamic>>> _parseFieldSets(dynamic raw) {
    if (raw == null) return const {};
    final map = Map<String, dynamic>.from(raw as Map);
    return map.map((key, value) {
      final list = (value as List)
          .cast<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
      return MapEntry(key, list);
    });
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
        screens,
        settings,
        guide,
        version,
        navigation,
        database,
        fieldSets,
      ];
}
