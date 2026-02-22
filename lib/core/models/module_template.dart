import 'package:cloud_firestore/cloud_firestore.dart';
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

  factory ModuleTemplate.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return ModuleTemplate(
      id: doc.id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      longDescription: data['longDescription'] as String? ?? '',
      icon: data['icon'] as String? ?? 'cube',
      color: data['color'] as String? ?? '#D94E33',
      category: data['category'] as String? ?? 'Productivity',
      tags: (data['tags'] as List?)?.cast<String>() ?? [],
      featured: data['featured'] as bool? ?? false,
      sortOrder: data['sortOrder'] as int? ?? 0,
      installCount: data['installCount'] as int? ?? 0,
      version: data['version'] as int? ?? 1,
      screens: _parseScreens(data['screens']),
      settings: Map<String, dynamic>.from(data['settings'] as Map? ?? {}),
      guide: (data['guide'] as List?)
              ?.cast<Map>()
              .map((m) => Map<String, String>.from(m))
              .toList() ??
          [],
      navigation: data['navigation'] != null
          ? ModuleNavigation.fromJson(
              Map<String, dynamic>.from(data['navigation'] as Map))
          : null,
      database: data['database'] != null
          ? ModuleDatabase.fromJson(
              Map<String, dynamic>.from(data['database'] as Map))
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'longDescription': longDescription,
      'icon': icon,
      'color': color,
      'category': category,
      'tags': tags,
      'featured': featured,
      'sortOrder': sortOrder,
      'installCount': installCount,
      'version': version,
      'screens': screens,
      'settings': settings,
      'guide': guide,
      if (navigation != null) 'navigation': navigation!.toJson(),
      if (database != null) 'database': database!.toJson(),
    };
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
