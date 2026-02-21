import 'action_builders.dart';

/// Static builders for query definitions.
class Query {
  Query._();

  static Json def(
    String sql, {
    Map<String, dynamic>? params,
    Map<String, dynamic>? defaults,
    List<String>? dependsOn,
  }) => {
    'sql': sql,
    if (params != null) 'params': params,
    if (defaults != null) 'defaults': defaults,
    if (dependsOn != null) 'dependsOn': dependsOn,
  };
}

/// Static builders for mutation definitions.
class Mut {
  Mut._();

  /// Single SQL string (bare form, backwards compat).
  static String sql(String sql) => sql;

  /// Object form with refresh + callbacks.
  static Json object({
    required String sql,
    List<String>? refresh,
    Json? onSuccess,
    Json? onError,
  }) => {
    'sql': sql,
    if (refresh != null) 'refresh': refresh,
    if (onSuccess != null) 'onSuccess': onSuccess,
    if (onError != null) 'onError': onError,
  };

  /// Multi-step transaction.
  static Json steps({
    required List<String> steps,
    List<String>? refresh,
    Json? onSuccess,
    Json? onError,
  }) => {
    'steps': steps,
    if (refresh != null) 'refresh': refresh,
    if (onSuccess != null) 'onSuccess': onSuccess,
    if (onError != null) 'onError': onError,
  };
}

/// Static builders for navigation configuration.
class Nav {
  Nav._();

  static Json bottomNav({required List<Json> items}) => {
    'bottomNav': {'items': items},
  };

  static Json drawer({required List<Json> items, String? header}) => {
    'drawer': {
      'items': items,
      if (header != null) 'header': header,
    },
  };

  static Json item({
    required String label,
    required String icon,
    required String screenId,
  }) => {
    'label': label,
    'icon': icon,
    'screenId': screenId,
  };
}

/// Static builder for database configuration.
class Db {
  Db._();

  static Json build({
    required Map<String, String> tableNames,
    required List<String> setup,
    required List<String> teardown,
  }) => {
    'tableNames': tableNames,
    'setup': setup,
    'teardown': teardown,
  };
}

/// Static builder for guide steps.
class Guide {
  Guide._();

  static Json step({required String title, required String body}) => {
    'title': title,
    'body': body,
  };
}

/// Static builder for a full module template definition.
class TemplateDef {
  TemplateDef._();

  static Json build({
    required String name,
    required String description,
    String? longDescription,
    required String icon,
    required String color,
    required String category,
    List<String>? tags,
    bool? featured,
    int? sortOrder,
    int? installCount,
    int? version,
    Map<String, dynamic>? settings,
    List<Json>? guide,
    Json? navigation,
    Json? database,
    required Map<String, Json> screens,
    Map<String, List<Json>>? fieldSets,
  }) => {
    'name': name,
    'description': description,
    if (longDescription != null) 'longDescription': longDescription,
    'icon': icon,
    'color': color,
    'category': category,
    if (tags != null) 'tags': tags,
    if (featured != null) 'featured': featured,
    if (sortOrder != null) 'sortOrder': sortOrder,
    'installCount': installCount ?? 0,
    'version': version ?? 1,
    'settings': settings ?? <String, dynamic>{},
    if (guide != null) 'guide': guide,
    if (navigation != null) 'navigation': navigation,
    if (database != null) 'database': database,
    'screens': screens,
    if (fieldSets != null) 'fieldSets': fieldSets,
  };
}
