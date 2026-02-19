import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../../features/blueprint/navigation/module_navigation.dart';
import '../../features/schema/models/module_schema.dart';
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
  final Map<String, ModuleSchema> schemas;
  final Map<String, Map<String, dynamic>> screens;
  final Map<String, dynamic> settings;
  final List<Map<String, String>> guide;
  final ModuleNavigation? navigation;

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
    this.schemas = const {'default': ModuleSchema()},
    this.screens = const {},
    this.settings = const {},
    this.guide = const [],
    this.navigation,
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
      schemas: _parseSchemas(data['schemas']),
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
      'schemas': schemas.map(
        (key, schema) => MapEntry(key, schema.toJson()),
      ),
      'screens': screens,
      'settings': settings,
      'guide': guide,
      if (navigation != null) 'navigation': navigation!.toJson(),
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
      schemas: schemas,
      screens: screens,
      settings: settings,
      guide: guide,
      version: version,
      navigation: navigation,
    );
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
        schemas,
        screens,
        settings,
        guide,
        navigation,
      ];
}
