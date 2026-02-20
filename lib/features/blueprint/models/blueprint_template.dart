import 'package:equatable/equatable.dart';

import '../navigation/module_navigation.dart';
import 'blueprint.dart';

/// Type-safe builder for an entire module template.
///
/// Wraps metadata, schemas, screens, navigation, and guide into one
/// object that produces the same `Map<String, dynamic>` structure as
/// the raw const maps, but with full IDE autocomplete and compile-time
/// checking.
///
/// ```dart
/// final template = BpTemplate(
///   name: 'Reading List',
///   icon: 'book',
///   schemas: { 'default': BpSchema(label: 'Book', fields: [...]) },
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
  final Map<String, BpSchema> schemas;
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
    this.schemas = const {},
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
    'schemas': schemas.map((key, schema) => MapEntry(key, schema.toJson())),
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
    schemas,
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

// ─── Schema ───

class BpSchema extends Equatable {
  final String label;
  final String? icon;
  final String? displayField;
  final List<BpField> fields;
  final List<BpSchemaEffect> effects;

  const BpSchema({
    required this.label,
    this.icon,
    this.displayField,
    this.fields = const [],
    this.effects = const [],
  });

  Map<String, dynamic> toJson() => {
    'label': label,
    if (icon != null) 'icon': icon,
    if (displayField != null) 'displayField': displayField,
    'fields': {for (final f in fields) f.key: f.toJson()},
    if (effects.isNotEmpty) 'effects': [for (final e in effects) e.toJson()],
  };

  @override
  List<Object?> get props => [label, icon, displayField, fields, effects];
}

// ─── Field ───

class BpField extends Equatable {
  final String key;
  final String type;
  final String label;
  final bool required;
  final List<String>? options;
  final String? schemaKey;
  final num? min;
  final num? max;

  const BpField.text(this.key, {required this.label, this.required = false})
    : type = 'text',
      options = null,
      schemaKey = null,
      min = null,
      max = null;

  const BpField.number(
    this.key, {
    required this.label,
    this.required = false,
    this.min,
    this.max,
  }) : type = 'number',
       options = null,
       schemaKey = null;

  const BpField.boolean(this.key, {required this.label})
    : type = 'boolean',
      required = false,
      options = null,
      schemaKey = null,
      min = null,
      max = null;

  const BpField.datetime(this.key, {required this.label, this.required = false})
    : type = 'datetime',
      options = null,
      schemaKey = null,
      min = null,
      max = null;

  const BpField.enum_(
    this.key, {
    required this.label,
    required List<String> this.options,
    this.required = false,
  }) : type = 'enumType',
       schemaKey = null,
       min = null,
       max = null;

  const BpField.multiEnum(
    this.key, {
    required this.label,
    required List<String> this.options,
  }) : type = 'multiEnum',
       required = false,
       schemaKey = null,
       min = null,
       max = null;

  const BpField.reference(
    this.key, {
    required this.label,
    required String this.schemaKey,
    this.required = false,
  }) : type = 'reference',
       options = null,
       min = null,
       max = null;

  const BpField.rating(
    this.key, {
    required this.label,
    this.min = 1,
    this.max = 5,
  }) : type = 'rating',
       required = false,
       options = null,
       schemaKey = null;

  const BpField.duration(this.key, {required this.label})
    : type = 'duration',
      required = false,
      options = null,
      schemaKey = null,
      min = null,
      max = null;

  const BpField.currency(this.key, {required this.label, this.required = false})
    : type = 'currency',
      options = null,
      schemaKey = null,
      min = null,
      max = null;

  const BpField.url(this.key, {required this.label})
    : type = 'url',
      required = false,
      options = null,
      schemaKey = null,
      min = null,
      max = null;

  const BpField.phone(this.key, {required this.label})
    : type = 'phone',
      required = false,
      options = null,
      schemaKey = null,
      min = null,
      max = null;

  const BpField.email(this.key, {required this.label})
    : type = 'email',
      required = false,
      options = null,
      schemaKey = null,
      min = null,
      max = null;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'key': key, 'type': type, 'label': label};
    if (required) json['required'] = true;
    if (options != null) json['options'] = options;
    if (schemaKey != null || min != null || max != null) {
      json['constraints'] = {
        if (schemaKey != null) 'schemaKey': schemaKey,
        if (min != null) 'min': min,
        if (max != null) 'max': max,
      };
    }
    return json;
  }

  @override
  List<Object?> get props => [
    key,
    type,
    label,
    required,
    options,
    schemaKey,
    min,
    max,
  ];
}

// ─── Schema Effects ───

class BpSchemaEffect extends Equatable {
  final String type;
  final String referenceField;
  final String targetField;
  final String amountField;
  final String operation;
  final num? min;

  const BpSchemaEffect.adjustReference({
    required this.referenceField,
    required this.targetField,
    required this.amountField,
    required this.operation,
    this.min,
  }) : type = 'adjust_reference';

  Map<String, dynamic> toJson() => {
    'type': type,
    'referenceField': referenceField,
    'targetField': targetField,
    'amountField': amountField,
    'operation': operation,
    if (min != null) 'min': min,
  };

  @override
  List<Object?> get props => [
    type,
    referenceField,
    targetField,
    amountField,
    operation,
    min,
  ];
}

