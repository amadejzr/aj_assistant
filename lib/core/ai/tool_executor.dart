import 'dart:convert';

import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../logging/log.dart';
import '../repositories/module_repository.dart';
import 'tool_definitions.dart';

const _tag = 'ToolExecutor';

class ToolExecutor {
  final AppDatabase _db;
  final ModuleRepository? _moduleRepository;
  final String? _userId;

  ToolExecutor({
    required AppDatabase db,
    ModuleRepository? moduleRepository,
    String? userId,
  })  : _db = db,
        _moduleRepository = moduleRepository,
        _userId = userId;

  static bool isReadOnly(String toolName) =>
      !toolsRequiringApproval.contains(toolName);

  /// Executes a read-only tool and returns the JSON result string.
  Future<String> executeReadOnly(
    String toolName,
    Map<String, dynamic> input,
  ) async {
    try {
      switch (toolName) {
        case 'queryEntries':
          return _queryEntries(input);
        case 'getModuleSummary':
          return _getModuleSummary(input);
        case 'runQuery':
          return _runQuery(input);
        default:
          return jsonEncode({'error': 'Unknown read-only tool: $toolName'});
      }
    } catch (e) {
      Log.e('Tool $toolName failed: $e', tag: _tag);
      return jsonEncode({'error': 'Tool execution failed: $e'});
    }
  }

  /// Resolves the table name for a tool call by looking up the module.
  Future<String?> resolveTableName(
    String moduleId,
    String? schemaKey,
  ) async {
    if (_moduleRepository == null || _userId == null) return null;
    final module = await _moduleRepository.getModule(_userId, moduleId);
    return module?.database?.tableNames[schemaKey ?? 'default'];
  }

  Future<String> _queryEntries(Map<String, dynamic> input) async {
    final tableName = input['tableName'] as String? ??
        await resolveTableName(
          input['moduleId'] as String,
          input['schemaKey'] as String?,
        );
    if (tableName == null) {
      return jsonEncode({'error': 'Could not resolve table name'});
    }

    final filters =
        (input['filters'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final orderBy = input['orderBy'] as String? ?? 'created_at';
    final orderDir =
        (input['orderDirection'] as String?)?.toUpperCase() == 'ASC'
            ? 'ASC'
            : 'DESC';
    final limit = (input['limit'] as num?)?.toInt().clamp(1, 50) ?? 20;

    var sql = 'SELECT * FROM "$tableName"';
    final variables = <Variable>[];

    if (filters.isNotEmpty) {
      final clauses = <String>[];
      for (final filter in filters) {
        final field = filter['field'] as String;
        final op = filter['op'] as String;
        clauses.add('"$field" $op ?');
        variables.add(Variable(filter['value']));
      }
      sql += ' WHERE ${clauses.join(' AND ')}';
    }

    sql += ' ORDER BY "$orderBy" $orderDir LIMIT ?';
    variables.add(Variable(limit));

    final rows = await _db.customSelect(sql, variables: variables).get();
    final entries = rows.map((r) => r.data).toList();

    return jsonEncode({
      'count': entries.length,
      'entries': entries,
    });
  }

  Future<String> _getModuleSummary(Map<String, dynamic> input) async {
    final tableName = input['tableName'] as String? ??
        await resolveTableName(
          input['moduleId'] as String,
          input['schemaKey'] as String?,
        );
    if (tableName == null) {
      return jsonEncode({'error': 'Could not resolve table name'});
    }

    // Column schema (so AI knows types for formatting)
    final pragmaRows = await _db
        .customSelect('PRAGMA table_info("$tableName")')
        .get();
    final columns = pragmaRows
        .map((r) => {
              'name': r.data['name'],
              'type': r.data['type'],
              'notnull': r.data['notnull'],
            })
        .toList();

    // Total count
    final countResult = await _db
        .customSelect('SELECT COUNT(*) as cnt FROM "$tableName"')
        .getSingle();
    final totalEntries = countResult.data['cnt'] as int;

    // Recent 5
    final recentRows = await _db
        .customSelect(
            'SELECT * FROM "$tableName" ORDER BY created_at DESC LIMIT 5')
        .get();
    final recentEntries = recentRows.map((r) => r.data).toList();

    return jsonEncode({
      'columns': columns,
      'totalEntries': totalEntries,
      'recentEntries': recentEntries,
    });
  }

  /// Returns an error message if [sql] is not a safe read-only SELECT,
  /// or null if it passes validation.
  static String? _validateSelectOnly(String sql) {
    if (sql.isEmpty) return 'SQL query is empty.';
    if (!sql.toUpperCase().startsWith('SELECT')) {
      return 'Only SELECT queries are allowed.';
    }
    // Reject multiple statements
    if (sql.contains(';')) {
      return 'Multiple statements are not allowed. Remove semicolons.';
    }
    // Reject DDL/DML keywords anywhere in the query
    final upper = sql.toUpperCase();
    const forbidden = [
      'INSERT ',
      'UPDATE ',
      'DELETE ',
      'DROP ',
      'ALTER ',
      'CREATE ',
      'REPLACE ',
      'ATTACH ',
      'DETACH ',
      'PRAGMA ',
    ];
    for (final keyword in forbidden) {
      if (upper.contains(keyword)) {
        return 'Query contains forbidden keyword: ${keyword.trim()}.';
      }
    }
    return null;
  }

  Future<String> _runQuery(Map<String, dynamic> input) async {
    final sql = (input['sql'] as String?)?.trim() ?? '';

    final rejection = _validateSelectOnly(sql);
    if (rejection != null) {
      return jsonEncode({'error': rejection});
    }

    final tableName = input['tableName'] as String? ??
        await resolveTableName(
          input['moduleId'] as String,
          input['schemaKey'] as String?,
        );
    if (tableName == null) {
      return jsonEncode({'error': 'Could not resolve table name'});
    }

    // Replace {{table}} placeholder with actual table name
    final resolvedSql = sql.replaceAll('{{table}}', '"$tableName"');

    final rows = await _db.customSelect(resolvedSql).get();
    final results = rows.map((r) => r.data).toList();

    return jsonEncode({
      'count': results.length,
      'results': results,
    });
  }
}
