import 'package:equatable/equatable.dart';

/// A parsed query definition from a screen's JSON blueprint.
class ScreenQuery extends Equatable {
  final String name;
  final String sql;
  final Map<String, String> params;
  final Map<String, Object> defaults;
  final List<String> dependsOn;

  const ScreenQuery({
    required this.name,
    required this.sql,
    this.params = const {},
    this.defaults = const {},
    this.dependsOn = const [],
  });

  factory ScreenQuery.fromJson(String name, Map<String, dynamic> json) {
    return ScreenQuery(
      name: name,
      sql: json['sql'] as String,
      params: (json['params'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as String)) ??
          const {},
      defaults: (json['defaults'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as Object)) ??
          const {},
      dependsOn: List<String>.from(json['dependsOn'] as List? ?? []),
    );
  }

  @override
  List<Object?> get props => [name, sql, params, defaults, dependsOn];
}

/// A declarative reminder to create after a mutation succeeds.
class ReminderSideEffect extends Equatable {
  final String type;
  final String frequency;
  final String titleField;
  final String messageField;
  final String? dateField;
  final String? timeField;
  final String? conditionField;
  final String? compoundField;
  final int hour;
  final int minute;

  const ReminderSideEffect({
    required this.type,
    required this.frequency,
    required this.titleField,
    required this.messageField,
    this.dateField,
    this.timeField,
    this.conditionField,
    this.compoundField,
    this.hour = 9,
    this.minute = 0,
  });

  factory ReminderSideEffect.fromJson(Map<String, dynamic> json) {
    return ReminderSideEffect(
      type: json['type'] as String? ?? 'scheduled',
      frequency: json['frequency'] as String? ?? 'once',
      titleField: json['titleField'] as String,
      messageField: json['messageField'] as String,
      dateField: json['dateField'] as String?,
      timeField: json['timeField'] as String?,
      conditionField: json['conditionField'] as String?,
      compoundField: json['compoundField'] as String?,
      hour: json['hour'] as int? ?? 9,
      minute: json['minute'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        type, frequency, titleField, messageField,
        dateField, timeField, conditionField, compoundField, hour, minute,
      ];
}

/// A parsed mutation from a screen's JSON blueprint.
///
/// Supports both single-step (bare SQL string or `{sql: ...}` map) and
/// multi-step (`{steps: [...]}`) mutations with optional metadata.
class ScreenMutation extends Equatable {
  final String? sql;
  final List<String>? steps;
  final List<String> refresh;
  final Map<String, dynamic>? onSuccess;
  final Map<String, dynamic>? onError;
  final List<ReminderSideEffect> reminders;

  const ScreenMutation({
    this.sql,
    this.steps,
    this.refresh = const [],
    this.onSuccess,
    this.onError,
    this.reminders = const [],
  });

  bool get isMultiStep => steps != null && steps!.isNotEmpty;

  /// Parses from either a bare SQL string or a map with metadata.
  factory ScreenMutation.fromJson(dynamic json) {
    if (json is String) return ScreenMutation(sql: json);
    if (json is Map<String, dynamic>) {
      return ScreenMutation(
        sql: json['sql'] as String?,
        steps: (json['steps'] as List?)?.cast<String>(),
        refresh: List<String>.from(json['refresh'] as List? ?? []),
        onSuccess: json['onSuccess'] as Map<String, dynamic>?,
        onError: json['onError'] as Map<String, dynamic>?,
        reminders: (json['reminders'] as List?)
                ?.map((e) =>
                    ReminderSideEffect.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
    }
    throw ArgumentError('Invalid mutation format: $json');
  }

  @override
  List<Object?> get props => [sql, steps, refresh, onSuccess, onError, reminders];
}

/// The set of mutations available for a screen (create, update, delete).
class ScreenMutations extends Equatable {
  final ScreenMutation? create;
  final ScreenMutation? update;
  final ScreenMutation? delete;

  const ScreenMutations({this.create, this.update, this.delete});

  factory ScreenMutations.fromJson(Map<String, dynamic> json) {
    final createJson = json['create'] ?? json['insert'];
    return ScreenMutations(
      create:
          createJson != null ? ScreenMutation.fromJson(createJson) : null,
      update:
          json['update'] != null ? ScreenMutation.fromJson(json['update']) : null,
      delete:
          json['delete'] != null ? ScreenMutation.fromJson(json['delete']) : null,
    );
  }

  @override
  List<Object?> get props => [create, update, delete];
}

/// Parses all queries from a screen's JSON blueprint.
List<ScreenQuery> parseScreenQueries(Map<String, dynamic> screenJson) {
  final queries = screenJson['queries'] as Map<String, dynamic>?;
  if (queries == null) return const [];

  return queries.entries
      .map((e) => ScreenQuery.fromJson(e.key, e.value as Map<String, dynamic>))
      .toList();
}
