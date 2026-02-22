import 'package:drift/drift.dart';

/// Lightweight Drift table reference for mutation notifications.
///
/// Used by [MutationExecutor] and [ChatActionExecutor] to trigger
/// Drift stream watchers when module tables are mutated via raw SQL.
class MutationTable extends ResultSetImplementation<MutationTable, Never> {
  @override
  final String entityName;

  final DatabaseConnectionUser _db;

  MutationTable(this.entityName, this._db);

  @override
  DatabaseConnectionUser get attachedDatabase => _db;

  @override
  MutationTable get asDslTable => this;

  @override
  List<GeneratedColumn> get $columns => const [];

  @override
  Map<String, GeneratedColumn> get columnsByName => const {};

  @override
  Never map(Map<String, dynamic> data, {String? tablePrefix}) {
    throw UnsupportedError('Mutation tables do not support mapping');
  }
}
