import 'package:equatable/equatable.dart';

import '../../features/blueprint/navigation/module_navigation.dart';
import '../database/module_database.dart';
import 'module.dart';

class ModuleTemplate extends Equatable {
  final String id;
  final String name;
  final String description;
  final String longDescription;
  final String icon;
  final String color;
  final String category;
  final List<String> tags;
  final bool featured;
  final int sortOrder;
  final int installCount;
  final int version;
  final Map<String, Map<String, dynamic>> screens;
  final Map<String, dynamic> settings;
  final List<Map<String, String>> guide;
  final ModuleNavigation? navigation;
  final ModuleDatabase? database;

  const ModuleTemplate({
    required this.id,
    required this.name,
    this.description = '',
    this.longDescription = '',
    this.icon = 'cube',
    this.color = '#D94E33',
    this.category = 'Productivity',
    this.tags = const [],
    this.featured = false,
    this.sortOrder = 0,
    this.installCount = 0,
    this.version = 1,
    this.screens = const {},
    this.settings = const {},
    this.guide = const [],
    this.navigation,
    this.database,
  });

  factory ModuleTemplate.fromJson(String id, Map<String, dynamic> json) {
    final rawScreens = json['screens'] as Map<String, dynamic>? ?? {};
    final screens = rawScreens.map(
      (key, value) => MapEntry(key, Map<String, dynamic>.from(value as Map)),
    );

    final rawGuide = json['guide'] as List?;
    final guide = rawGuide
            ?.map((e) => Map<String, String>.from(e as Map))
            .toList() ??
        [];

    return ModuleTemplate(
      id: id,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      longDescription: json['longDescription'] as String? ?? '',
      icon: json['icon'] as String? ?? 'cube',
      color: json['color'] as String? ?? '#D94E33',
      category: json['category'] as String? ?? 'Productivity',
      tags: List<String>.from(json['tags'] as List? ?? []),
      featured: json['featured'] as bool? ?? false,
      sortOrder: json['sortOrder'] as int? ?? 0,
      installCount: json['installCount'] as int? ?? 0,
      version: json['version'] as int? ?? 1,
      screens: screens,
      settings: Map<String, dynamic>.from(json['settings'] as Map? ?? {}),
      guide: guide,
      navigation: json['navigation'] != null
          ? ModuleNavigation.fromJson(
              Map<String, dynamic>.from(json['navigation'] as Map))
          : null,
      database: json['database'] != null
          ? ModuleDatabase.fromJson(
              Map<String, dynamic>.from(json['database'] as Map))
          : null,
    );
  }

  /// Converts this template into a user-owned [Module] with the given [newId].
  Module toModule(String newId) {
    return Module(
      id: newId,
      name: name,
      description: description,
      icon: icon,
      color: color,
      sortOrder: 0,
      screens: screens,
      settings: settings,
      guide: guide,
      version: version,
      navigation: navigation,
      database: database,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        longDescription,
        icon,
        color,
        category,
        tags,
        featured,
        sortOrder,
        installCount,
        version,
        screens,
        settings,
        guide,
        navigation,
        database,
      ];
}
