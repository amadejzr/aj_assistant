import 'package:equatable/equatable.dart';

/// A parsed query definition from a screen's JSON blueprint.
class ScreenQuery extends Equatable {
  final String name;
  final String sql;
  final Map<String, String> params;
  final Map<String, Object> defaults;

  const ScreenQuery({
    required this.name,
    required this.sql,
    this.params = const {},
    this.defaults = const {},
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
    );
  }

  @override
  List<Object?> get props => [name, sql, params, defaults];
}

/// A parsed mutation SQL statement from a screen's JSON blueprint.
class ScreenMutation extends Equatable {
  final String sql;

  const ScreenMutation({required this.sql});

  @override
  List<Object?> get props => [sql];
}

/// The set of mutations available for a screen (create, update, delete).
class ScreenMutations extends Equatable {
  final ScreenMutation? create;
  final ScreenMutation? update;
  final ScreenMutation? delete;

  const ScreenMutations({this.create, this.update, this.delete});

  factory ScreenMutations.fromJson(Map<String, dynamic> json) {
    return ScreenMutations(
      create: json['create'] != null
          ? ScreenMutation(sql: json['create'] as String)
          : null,
      update: json['update'] != null
          ? ScreenMutation(sql: json['update'] as String)
          : null,
      delete: json['delete'] != null
          ? ScreenMutation(sql: json['delete'] as String)
          : null,
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
