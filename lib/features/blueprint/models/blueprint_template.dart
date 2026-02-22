import 'package:equatable/equatable.dart';

import '../../../core/database/module_database.dart';
import '../navigation/module_navigation.dart';
import 'blueprint.dart';

/// Type-safe builder for an entire module template.
///
/// Wraps metadata, screens, navigation, database, and guide into one
/// object that produces the same `Map<String, dynamic>` structure as
/// the raw const maps, but with full IDE autocomplete and compile-time
/// checking.
///
/// ```dart
/// final template = BpTemplate(
///   name: 'Reading List',
///   icon: 'book',
///   database: ModuleDatabase(tableNames: {'default': 'books'}, setup: [...]),
///   screens: { 'main': BpScreen(title: 'Library', children: [...]) },
/// );
/// // Use template.toJson() to seed Firestore.
/// ```
class BpTemplate extends Equatable {
  final String name;
  final String description;
  final String? longDescription;
  final String icon;
  final String color;
  final String category;
  final List<String> tags;
  final bool featured;
  final int sortOrder;
  final int version;
  final Map<String, dynamic> settings;
  final List<BpGuideStep> guide;
  final ModuleNavigation? navigation;
  final ModuleDatabase? database;
  final Map<String, Blueprint> screens;

  const BpTemplate({
    required this.name,
    this.description = '',
    this.longDescription,
    this.icon = 'cube',
    this.color = '#D94E33',
    this.category = 'General',
    this.tags = const [],
    this.featured = false,
    this.sortOrder = 0,
    this.version = 1,
    this.settings = const {},
    this.guide = const [],
    this.navigation,
    this.database,
    this.screens = const {},
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    if (longDescription != null) 'longDescription': longDescription,
    'icon': icon,
    'color': color,
    'category': category,
    'tags': tags,
    'featured': featured,
    'sortOrder': sortOrder,
    'installCount': 0,
    'version': version,
    'settings': settings,
    'guide': [for (final g in guide) g.toJson()],
    if (navigation != null) 'navigation': navigation!.toJson(),
    if (database != null) 'database': database!.toJson(),
    'screens': screens.map((key, screen) {
      final json = screen.toJson();
      json['id'] = key;
      return MapEntry(key, json);
    }),
  };

  @override
  List<Object?> get props => [
    name,
    description,
    longDescription,
    icon,
    color,
    category,
    tags,
    featured,
    sortOrder,
    version,
    settings,
    guide,
    navigation,
    database,
    screens,
  ];
}

// ─── Guide ───

class BpGuideStep extends Equatable {
  final String title;
  final String body;

  const BpGuideStep({required this.title, required this.body});

  Map<String, dynamic> toJson() => {'title': title, 'body': body};

  @override
  List<Object?> get props => [title, body];
}
