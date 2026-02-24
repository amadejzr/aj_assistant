import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/module_database.dart';
import '../../../core/database/mutation_table.dart';
import '../../../core/database/schema_manager.dart';
import '../../../core/logging/log.dart';
import '../../../core/models/module.dart';
import '../../../core/repositories/module_repository.dart';
import '../../blueprint/navigation/module_navigation.dart';
import '../models/message.dart';

const _tag = 'ChatActionExecutor';

/// Executes approved chat actions (createEntry, updateEntry, etc.)
/// against the local Drift database.
class ChatActionExecutor {
  final AppDatabase _db;
  final ModuleRepository _moduleRepository;
  final String _userId;

  ChatActionExecutor({
    required AppDatabase db,
    required ModuleRepository moduleRepository,
    required String userId,
  })  : _db = db,
        _moduleRepository = moduleRepository,
        _userId = userId;

  /// Executes a single pending action and returns a human-readable result.
  Future<String> execute(PendingAction action) async {
    switch (action.name) {
      case 'createEntry':
        return _createEntry(action.input);
      case 'createEntries':
        return _createEntries(action.input);
      case 'updateEntry':
        return _updateEntry(action.input);
      case 'updateEntries':
        return _updateEntries(action.input);
      case 'createModule':
        return _createModule(action.input);
      default:
        return 'Unsupported action: ${action.name}';
    }
  }

  Future<String> _createEntry(Map<String, dynamic> input) async {
    final moduleId = input['moduleId'] as String;
    final schemaKey = input['schemaKey'] as String;
    final data = Map<String, dynamic>.from(input['data'] as Map);

    final tableName = await _resolveTableName(moduleId, schemaKey);
    if (tableName == null) {
      return 'Could not find table for $schemaKey';
    }

    final id = _generateId();
    final now = DateTime.now().millisecondsSinceEpoch;
    data['id'] = id;
    data['created_at'] = now;
    data['updated_at'] = now;

    await _enableForeignKeys();

    final columns = data.keys.map((k) => '"$k"').join(', ');
    final placeholders = List.filled(data.length, '?').join(', ');
    final sql = 'INSERT INTO "$tableName" ($columns) VALUES ($placeholders)';
    final variables = data.values.map((v) => Variable(v)).toList();

    await _db.customInsert(
      sql,
      variables: variables,
      updates: {MutationTable(tableName, _db)},
    );

    Log.i('Created entry $id in $tableName', tag: _tag);
    return 'Created entry in $schemaKey';
  }

  Future<String> _createEntries(Map<String, dynamic> input) async {
    final moduleId = input['moduleId'] as String;
    final schemaKey = input['schemaKey'] as String;
    final entries = List<Map<String, dynamic>>.from(
      (input['entries'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );

    final tableName = await _resolveTableName(moduleId, schemaKey);
    if (tableName == null) {
      return 'Could not find table for $schemaKey';
    }

    await _enableForeignKeys();

    final tableRef = {MutationTable(tableName, _db)};
    var count = 0;

    await _db.transaction(() async {
      for (final entry in entries) {
        final data = Map<String, dynamic>.from(entry['data'] as Map? ?? entry);
        final id = _generateId();
        final now = DateTime.now().millisecondsSinceEpoch;
        data['id'] = id;
        data['created_at'] = now;
        data['updated_at'] = now;

        final columns = data.keys.map((k) => '"$k"').join(', ');
        final placeholders = List.filled(data.length, '?').join(', ');
        final sql =
            'INSERT INTO "$tableName" ($columns) VALUES ($placeholders)';
        final variables = data.values.map((v) => Variable(v)).toList();

        await _db.customInsert(
          sql,
          variables: variables,
          updates: tableRef,
        );
        count++;
      }
    });

    Log.i('Created $count entries in $tableName', tag: _tag);
    return 'Created $count entries in $schemaKey';
  }

  Future<String> _updateEntry(Map<String, dynamic> input) async {
    final moduleId = input['moduleId'] as String;
    final entryId = input['entryId'] as String;
    final data = Map<String, dynamic>.from(input['data'] as Map);

    final now = DateTime.now().millisecondsSinceEpoch;
    data['updated_at'] = now;

    await _enableForeignKeys();

    // updateEntry has no schemaKey — find the table containing the entry
    final tableName = input['schemaKey'] != null
        ? await _resolveTableName(moduleId, input['schemaKey'] as String)
        : await _findTableForEntry(moduleId, entryId);

    if (tableName == null) {
      return 'Could not find entry $entryId';
    }

    final setClauses = data.keys.map((k) => '"$k" = ?').join(', ');
    final sql = 'UPDATE "$tableName" SET $setClauses WHERE id = ?';
    final variables = [
      ...data.values.map((v) => Variable(v)),
      Variable(entryId),
    ];

    final rowsAffected = await _db.customUpdate(
      sql,
      variables: variables,
      updates: {MutationTable(tableName, _db)},
      updateKind: UpdateKind.update,
    );

    if (rowsAffected == 0) {
      return 'Entry $entryId not found';
    }

    Log.i('Updated entry $entryId in $tableName', tag: _tag);
    return 'Updated entry';
  }

  Future<String> _updateEntries(Map<String, dynamic> input) async {
    final moduleId = input['moduleId'] as String;
    final entries = List<Map<String, dynamic>>.from(
      (input['entries'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );

    await _enableForeignKeys();

    var count = 0;

    await _db.transaction(() async {
      for (final entry in entries) {
        final entryId = entry['entryId'] as String;
        final data = Map<String, dynamic>.from(entry['data'] as Map);
        final now = DateTime.now().millisecondsSinceEpoch;
        data['updated_at'] = now;

        final tableName = entry['schemaKey'] != null
            ? await _resolveTableName(moduleId, entry['schemaKey'] as String)
            : await _findTableForEntry(moduleId, entryId);

        if (tableName == null) continue;

        final setClauses = data.keys.map((k) => '"$k" = ?').join(', ');
        final sql = 'UPDATE "$tableName" SET $setClauses WHERE id = ?';
        final variables = [
          ...data.values.map((v) => Variable(v)),
          Variable(entryId),
        ];

        await _db.customUpdate(
          sql,
          variables: variables,
          updates: {MutationTable(tableName, _db)},
          updateKind: UpdateKind.update,
        );
        count++;
      }
    });

    Log.i('Updated $count entries', tag: _tag);
    return 'Updated $count entries';
  }

  Future<String> _createModule(Map<String, dynamic> input) async {
    final name = input['name'] as String;
    final description = input['description'] as String? ?? '';
    final icon = input['icon'] as String? ?? 'cube';
    final color = input['color'] as String? ?? '#D94E33';

    final dbInput = Map<String, dynamic>.from(input['database'] as Map);
    final database = ModuleDatabase(
      tableNames: Map<String, String>.from(dbInput['tableNames'] as Map),
      setup: List<String>.from(dbInput['setup'] as List),
      teardown: List<String>.from(dbInput['teardown'] as List? ?? []),
    );

    final screensRaw = Map<String, dynamic>.from(input['screens'] as Map);
    final screens = screensRaw.map(
      (key, value) => MapEntry(key, Map<String, dynamic>.from(value as Map)),
    );

    ModuleNavigation? navigation;
    if (input['navigation'] != null) {
      navigation = ModuleNavigation.fromJson(
        Map<String, dynamic>.from(input['navigation'] as Map),
      );
    }

    List<Map<String, String>> guide = const [];
    if (input['guide'] != null) {
      guide = (input['guide'] as List)
          .cast<Map>()
          .map((m) => Map<String, String>.from(m))
          .toList();
    }

    final moduleId = _generateId();
    final module = Module(
      id: moduleId,
      name: name,
      description: description,
      icon: icon,
      color: color,
      screens: screens,
      database: database,
      navigation: navigation,
      guide: guide,
    );

    await _moduleRepository.createModule(_userId, module);
    await SchemaManager(db: _db).installModule(module);

    Log.i('Created module "$name" (id: $moduleId)', tag: _tag);
    return 'Created module "$name"';
  }

  /// Resolves a module's schema key to its SQLite table name.
  Future<String?> _resolveTableName(String moduleId, String schemaKey) async {
    final module = await _moduleRepository.getModule(_userId, moduleId);
    if (module == null) {
      Log.e('Module $moduleId not found', tag: _tag);
      return null;
    }
    return module.database?.tableNames[schemaKey];
  }

  /// Finds which table contains an entry by checking all module tables.
  Future<String?> _findTableForEntry(String moduleId, String entryId) async {
    final module = await _moduleRepository.getModule(_userId, moduleId);
    if (module?.database == null) return null;

    for (final tableName in module!.database!.tableNames.values) {
      final results = await _db.customSelect(
        'SELECT 1 FROM "$tableName" WHERE id = ? LIMIT 1',
        variables: [Variable(entryId)],
      ).get();
      if (results.isNotEmpty) return tableName;
    }
    return null;
  }

  Future<void> _enableForeignKeys() async {
    await _db.customStatement('PRAGMA foreign_keys = ON');
  }

  String _generateId() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch;
    final hash = Object.hash(now, timestamp).toUnsigned(32).toRadixString(16);
    return '${timestamp}_$hash';
  }
}
