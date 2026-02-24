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
