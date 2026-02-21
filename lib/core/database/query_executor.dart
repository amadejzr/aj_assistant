import 'dart:async';

import 'package:drift/drift.dart' hide QueryExecutor;

import 'app_database.dart';
import 'screen_query.dart';

final _paramPattern = RegExp(r':([a-zA-Z_][a-zA-Z0-9_]*)');

/// Executes parameterized SQL queries against module-owned tables.
class QueryExecutor {
  final AppDatabase db;
  final Set<String> moduleTableNames;

  late final Set<ResultSetImplementation> tableRefs = moduleTableNames
      .map((name) => _DynamicTable(name, db))
      .toSet();

  QueryExecutor({required this.db, required this.moduleTableNames});

  /// Executes a single query with resolved params, returns rows as maps.
  Future<List<Map<String, dynamic>>> execute(
    ScreenQuery query,
    Map<String, Object> resolvedParams,
  ) async {
    final (sql, variables) = _bind(query, resolvedParams);
    final rows = await db.customSelect(sql, variables: variables).get();
    return rows.map(_rowToMap).toList();
  }

  /// Returns a stream that re-emits query results whenever module tables change.
  Stream<List<Map<String, dynamic>>> watch(
    ScreenQuery query,
    Map<String, Object> resolvedParams,
  ) {
    final (sql, variables) = _bind(query, resolvedParams);
    return db
        .customSelect(sql, variables: variables, readsFrom: tableRefs)
        .watch()
        .map((rows) => rows.map(_rowToMap).toList());
  }

  /// Executes a paginated query with LIMIT/OFFSET appended.
  Future<List<Map<String, dynamic>>> executePaginated(
    ScreenQuery query,
    Map<String, Object> resolvedParams, {
    required int limit,
    required int offset,
  }) async {
    // Append LIMIT/OFFSET if not already in the SQL
    var sql = query.sql;
    final upperSql = sql.toUpperCase();
    if (!upperSql.contains('LIMIT')) {
      sql = '$sql LIMIT $limit OFFSET $offset';
    }

    final paginatedQuery = ScreenQuery(
      name: query.name,
      sql: sql,
      params: query.params,
      defaults: query.defaults,
    );

    return execute(paginatedQuery, resolvedParams);
  }

  /// Executes all queries for a screen, returns named results.
  Future<Map<String, List<Map<String, dynamic>>>> executeAll(
    List<ScreenQuery> queries,
    Map<String, Object> resolvedParams,
  ) async {
    final results = await Future.wait(
      queries.map((q) => execute(q, resolvedParams)),
    );
    return {
      for (var i = 0; i < queries.length; i++) queries[i].name: results[i],
    };
  }

  /// Watches all queries for a screen, emits whenever any result changes.
  ///
  /// Query errors are captured per-query in [errors] instead of propagating.
  Stream<QueryWatchResult> watchAll(
    List<ScreenQuery> queries,
    Map<String, Object> resolvedParams,
  ) {
    final controller = StreamController<QueryWatchResult>();
    final latest = <String, List<Map<String, dynamic>>>{};
    final errors = <String, String>{};
    final subscriptions = <StreamSubscription>[];

    for (final query in queries) {
      final sub = watch(query, resolvedParams).listen(
        (rows) {
          latest[query.name] = rows;
          errors.remove(query.name);
          if (latest.length + errors.length == queries.length) {
            controller.add(QueryWatchResult(
              results: Map.of(latest),
              errors: Map.of(errors),
            ));
          }
        },
        onError: (Object e) {
          errors[query.name] = e.toString();
          if (latest.length + errors.length == queries.length) {
            controller.add(QueryWatchResult(
              results: Map.of(latest),
              errors: Map.of(errors),
            ));
          }
        },
      );
      subscriptions.add(sub);
    }

    controller.onCancel = () {
      for (final sub in subscriptions) {
        sub.cancel();
      }
    };

    return controller.stream;
  }

  /// Binds :paramName placeholders in SQL to positional ? variables.
  (String, List<Variable>) _bind(
    ScreenQuery query,
    Map<String, Object> resolvedParams,
  ) {
    final variables = <Variable>[];

    final sql = query.sql.replaceAllMapped(_paramPattern, (match) {
      final paramName = match.group(1)!;
      final value =
          resolvedParams[paramName] ?? query.defaults[paramName];
      variables.add(Variable(value));
      return '?';
    });

    return (sql, variables);
  }

  Map<String, dynamic> _rowToMap(QueryRow row) {
    return row.data;
  }
}

/// Result of watching all queries for a screen.
class QueryWatchResult {
  final Map<String, List<Map<String, dynamic>>> results;
  final Map<String, String> errors;

  const QueryWatchResult({
    this.results = const {},
    this.errors = const {},
  });
}

/// Lightweight Drift table reference for dynamic (non-Drift-managed) tables.
/// Only [entityName] matters — used for stream change tracking.
class _DynamicTable extends ResultSetImplementation<_DynamicTable, Never> {
  @override
  final String entityName;

  final DatabaseConnectionUser _db;

  _DynamicTable(this.entityName, this._db);

  @override
  DatabaseConnectionUser get attachedDatabase => _db;

  @override
  _DynamicTable get asDslTable => this;

  @override
  List<GeneratedColumn> get $columns => const [];

  @override
  Map<String, GeneratedColumn> get columnsByName => const {};

  @override
  Never map(Map<String, dynamic> data, {String? tablePrefix}) {
    throw UnsupportedError('Dynamic tables do not support mapping');
  }
}
