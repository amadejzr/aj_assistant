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

    sql += ' ORDER BY "$orderBy" DESC LIMIT ?';
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
      'totalEntries': totalEntries,
      'recentEntries': recentEntries,
    });
  }
}
