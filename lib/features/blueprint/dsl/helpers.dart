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
    'params': ?params,
    'defaults': ?defaults,
    'dependsOn': ?dependsOn,
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
    List<Json>? reminders,
  }) => {
    'sql': sql,
    'refresh': ?refresh,
    'onSuccess': ?onSuccess,
    'onError': ?onError,
    'reminders': ?reminders,
  };

  /// Multi-step transaction.
  static Json steps({
    required List<String> steps,
    List<String>? refresh,
    Json? onSuccess,
    Json? onError,
    List<Json>? reminders,
  }) => {
    'steps': steps,
    'refresh': ?refresh,
    'onSuccess': ?onSuccess,
    'onError': ?onError,
    'reminders': ?reminders,
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
      'header': ?header,
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
    'longDescription': ?longDescription,
    'icon': icon,
    'color': color,
    'category': category,
    'tags': ?tags,
    'featured': ?featured,
    'sortOrder': ?sortOrder,
    'installCount': installCount ?? 0,
    'version': version ?? 1,
    'settings': settings ?? <String, dynamic>{},
    'guide': ?guide,
    'navigation': ?navigation,
    'database': ?database,
    'screens': screens,
    'fieldSets': ?fieldSets,
  };
}

/// DSL for declaring reminder side-effects on mutations.
class Reminders {
  Reminders._();

  /// Creates a one-shot reminder from form field values.
  ///
  /// - [titleField]: template string like `'Hike: {{name}}'` or a bare field key
  /// - [messageField]: template string or bare field key
  /// - [dateField]: form field key containing the reminder date (epoch int)
  /// - [timeField]: optional form field key for time (overrides hour/minute defaults)
  /// - [conditionField]: optional form field key — reminder only created when truthy
  /// - [hour]/[minute]: default time if no timeField provided (defaults 9:00)
  static Json onFormSubmit({
    required String titleField,
    required String messageField,
    required String dateField,
    String? timeField,
    String? conditionField,
    int hour = 9,
    int minute = 0,
  }) => {
    'type': 'scheduled',
    'frequency': 'once',
    'titleField': titleField,
    'messageField': messageField,
    'dateField': dateField,
    'timeField': ?timeField,
    'conditionField': ?conditionField,
    'hour': hour,
    'minute': minute,
  };
}
