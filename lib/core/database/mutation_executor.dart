import 'package:drift/drift.dart';

import 'app_database.dart';
import 'screen_query.dart';

final _paramPattern = RegExp(r':([a-zA-Z_][a-zA-Z0-9_]*)');

/// Executes CREATE/UPDATE/DELETE mutations against module-owned tables.
class MutationExecutor {
  final AppDatabase db;
  final Set<String> moduleTableNames;

  late final Set<ResultSetImplementation> _tableRefs = moduleTableNames
      .map((name) => _MutationTable(name, db))
      .toSet();

  MutationExecutor({required this.db, required this.moduleTableNames});

  /// Runs a CREATE mutation. Auto-generates :id, :created_at, :updated_at.
  /// Returns the generated ID.
  Future<String> create(
    ScreenMutation mutation,
    Map<String, dynamic> formValues,
  ) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = _generateId();

    final params = {
      ...formValues,
      'id': id,
      'created_at': now,
      'updated_at': now,
    };

    await _enableForeignKeys();

    if (mutation.isMultiStep) {
      await _executeTransaction(mutation.steps!, params);
      return id;
    }

    final (sql, variables) = _bind(mutation.sql!, params);
    await db.customInsert(sql, variables: variables, updates: _tableRefs);

    return id;
  }

  /// Runs an UPDATE mutation. Auto-generates :updated_at. Requires :id.
  Future<void> update(
    ScreenMutation mutation,
    String id,
    Map<String, dynamic> formValues,
  ) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    final params = {
      ...formValues,
      'id': id,
      'updated_at': now,
    };

    await _enableForeignKeys();

    if (mutation.isMultiStep) {
      await _executeTransaction(mutation.steps!, params);
      return;
    }

    final (sql, variables) = _bind(mutation.sql!, params);
    await db.customUpdate(
      sql,
      variables: variables,
      updates: _tableRefs,
      updateKind: UpdateKind.update,
    );
  }

  /// Runs a DELETE mutation. Requires :id.
  Future<void> delete(ScreenMutation mutation, String id) async {
    final params = {'id': id};

    await _enableForeignKeys();

    if (mutation.isMultiStep) {
      await _executeTransaction(mutation.steps!, params);
      return;
    }

    final (sql, variables) = _bind(mutation.sql!, params);
    await db.customUpdate(
      sql,
      variables: variables,
      updates: _tableRefs,
      updateKind: UpdateKind.delete,
    );
  }

  /// Executes multiple SQL statements in a single transaction.
  Future<void> _executeTransaction(
    List<String> sqls,
    Map<String, dynamic> params,
  ) async {
    await db.transaction(() async {
      for (final sql in sqls) {
        final (boundSql, variables) = _bind(sql, params);
        await db.customUpdate(
          boundSql,
          variables: variables,
          updates: _tableRefs,
        );
      }
    });
  }

  Future<void> _enableForeignKeys() async {
    await db.customStatement('PRAGMA foreign_keys = ON');
  }

  String _generateId() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch;
    final hash = Object.hash(now, timestamp).toUnsigned(32).toRadixString(16);
    return '${timestamp}_$hash';
  }

  (String, List<Variable>) _bind(String sql, Map<String, dynamic> params) {
    final variables = <Variable>[];

    final bound = sql.replaceAllMapped(_paramPattern, (match) {
      final paramName = match.group(1)!;
      final value = params[paramName];
      variables.add(Variable(value));
      return '?';
    });

    return (bound, variables);
  }
}

/// Lightweight Drift table reference for mutation notifications.
class _MutationTable extends ResultSetImplementation<_MutationTable, Never> {
  @override
  final String entityName;

  final DatabaseConnectionUser _db;

  _MutationTable(this.entityName, this._db);

  @override
  DatabaseConnectionUser get attachedDatabase => _db;

  @override
  _MutationTable get asDslTable => this;

  @override
  List<GeneratedColumn> get $columns => const [];

  @override
  Map<String, GeneratedColumn> get columnsByName => const {};

  @override
  Never map(Map<String, dynamic> data, {String? tablePrefix}) {
    throw UnsupportedError('Mutation tables do not support mapping');
  }
}
