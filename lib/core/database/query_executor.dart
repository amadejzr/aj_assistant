import 'package:drift/drift.dart' hide QueryExecutor;

import 'app_database.dart';
import 'screen_query.dart';

final _paramPattern = RegExp(r':([a-zA-Z_][a-zA-Z0-9_]*)');

/// Executes parameterized SQL queries against module-owned tables.
class QueryExecutor {
  final AppDatabase db;
  final Set<String> moduleTableNames;

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
