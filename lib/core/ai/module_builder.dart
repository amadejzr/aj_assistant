import 'dart:convert';

import '../database/field_type.dart';
import '../database/module_database.dart';
import '../database/table_name_generator.dart';
import '../database/type_mapping.dart';
import '../models/module.dart';
import '../../features/blueprint/navigation/module_navigation.dart';

/// SQL generation helpers for AI-driven module creation.
///
/// The AI defines modules with structured column definitions. This class
/// converts those definitions into proper SQL statements that
/// [SchemaManager] can execute to set up local SQLite tables.
class ModuleBuilder {
  ModuleBuilder._();

  // ---------------------------------------------------------------------------
  // Table naming
  // ---------------------------------------------------------------------------

  /// Generates a table name from [moduleName] and [schemaKey].
  ///
  /// Delegates to [TableNameGenerator.schemaTable].
  static String tableName(String moduleName, String schemaKey) =>
      TableNameGenerator.schemaTable(moduleName, schemaKey);

  // ---------------------------------------------------------------------------
  // CREATE TABLE
  // ---------------------------------------------------------------------------

  /// Generates a `CREATE TABLE IF NOT EXISTS` statement from structured
  /// [columns].
  ///
  /// Each column is a map with `name` (String), `type` (String: text,
  /// integer, real), and optionally `required` (bool).
  ///
  /// The statement always begins with `id TEXT PRIMARY KEY` and ends with
  /// `created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL`.
  static String generateCreateTable(
    String table,
    List<Map<String, dynamic>> columns,
  ) {
    final parts = <String>['id TEXT PRIMARY KEY'];

    for (final col in columns) {
      final name = col['name'] as String;
      final type = _sqlType(col['type'] as String);
      final required = col['required'] as bool? ?? false;
      parts.add('$name $type${required ? ' NOT NULL' : ''}');
    }

    parts.add('created_at INTEGER NOT NULL');
    parts.add('updated_at INTEGER NOT NULL');

    return 'CREATE TABLE IF NOT EXISTS "$table" (${parts.join(', ')})';
  }

  // ---------------------------------------------------------------------------
  // Mutations (INSERT / UPDATE / DELETE)
  // ---------------------------------------------------------------------------

  /// Generates mutation SQL statements for form screens.
  ///
  /// Only keys whose flags are `true` are included in the returned map:
  /// - `insert` for [isCreate]
  /// - `update` for [isUpdate]
  /// - `delete` for [isDelete]
  static Map<String, String> generateMutations(
    String table,
    List<Map<String, dynamic>> columns, {
    bool isCreate = false,
    bool isUpdate = false,
    bool isDelete = false,
  }) {
    final result = <String, String>{};

    final colNames = columns.map((c) => c['name'] as String).toList();

    if (isCreate) {
      result['insert'] = _insertSql(table, colNames);
    }
    if (isUpdate) {
      result['update'] = _updateSql(table, colNames);
    }
    if (isDelete) {
      result['delete'] = 'DELETE FROM "$table" WHERE id = :id';
    }

    return result;
  }

  // ---------------------------------------------------------------------------
  // Table reference resolution
  // ---------------------------------------------------------------------------

  /// Replaces `{{schemaKey}}` placeholders in [sql] with quoted table names
  /// from [tableNames].
  ///
  /// Unmatched placeholders are left as-is.
  static String resolveTableReferences(
    String sql,
    Map<String, String> tableNames,
  ) {
    return sql.replaceAllMapped(
      RegExp(r'\{\{(\w+)\}\}'),
      (match) {
        final key = match.group(1)!;
        final resolved = tableNames[key];
        if (resolved != null) return '"$resolved"';
        return match.group(0)!;
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  static String _sqlType(String type) =>
      TypeMapping.sqlType(FieldType.fromString(type));

  static String _insertSql(String table, List<String> colNames) {
    final allCols = ['id', ...colNames, 'created_at', 'updated_at'];
    final quoted = allCols.map((c) => '"$c"').join(', ');
    final params = allCols.map((c) => ':$c').join(', ');
    return 'INSERT INTO "$table" ($quoted) VALUES ($params)';
  }

  static String _updateSql(String table, List<String> colNames) {
    final sets = <String>[];
    for (final col in colNames) {
      sets.add('"$col" = COALESCE(:$col, "$col")');
    }
    sets.add('"updated_at" = :updated_at');

    return 'UPDATE "$table" SET ${sets.join(', ')} WHERE id = :id';
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  /// Converts simplified `createModule` tool input into a full [Module].
  ///
  /// The input contains structured column definitions, screens with
  /// `{{schemaKey}}` query references, and optional navigation/guide. This
  /// method generates all SQL (CREATE TABLE, INSERT, UPDATE, DELETE) and
  /// resolves table references.
  static Module build(Map<String, dynamic> input) {
    final name = input['name'] as String;
    final description = input['description'] as String? ?? '';
    final icon = input['icon'] as String? ?? 'cube';
    final color = input['color'] as String? ?? '#D94E33';

    // -- 1. Process tables: generate names, CREATE TABLE, DROP TABLE ----------
    final tablesInput = Map<String, dynamic>.from(input['tables'] as Map);
    final tableNames = <String, String>{};
    final setup = <String>[];
    final teardown = <String>[];

    for (final entry in tablesInput.entries) {
      final schemaKey = entry.key;
      final tableData = Map<String, dynamic>.from(entry.value as Map);
      final columns = (tableData['columns'] as List)
          .map((c) => Map<String, dynamic>.from(c as Map))
          .toList();

      final tName = tableName(name, schemaKey);
      tableNames[schemaKey] = tName;
      setup.add(generateCreateTable(tName, columns));
      teardown.add('DROP TABLE IF EXISTS "$tName"');
    }

    // -- 2. Process screens: resolve queries, generate mutations --------------
    final screensInput = Map<String, dynamic>.from(input['screens'] as Map);
    final screens = <String, Map<String, dynamic>>{};

    for (final screenEntry in screensInput.entries) {
      final screenId = screenEntry.key;
      final screenData =
          Map<String, dynamic>.from(screenEntry.value as Map);

      // Resolve {{key}} in all query SQL
      _resolveQueriesInScreen(screenData, tableNames);

      final screenType = screenData['type'] as String?;

      if (screenType == 'form_screen') {
        // Read the target table key for mutation generation
        final targetTableKey = screenData['table'] as String?;
        if (targetTableKey != null) {
          final targetTable = tableNames[targetTableKey]!;
          final targetColumns =
              _columnsForTable(tablesInput, targetTableKey);

          final hasSubmitLabel = screenData.containsKey('submitLabel');
          final hasEditLabel = screenData.containsKey('editLabel');
          final hasDeleteAction = _containsString(screenData, 'delete_entry');

          final isCreate = hasSubmitLabel || (!hasSubmitLabel && !hasEditLabel);
          final isUpdate = hasEditLabel;
          final isDelete = hasDeleteAction;

          final mutations = generateMutations(
            targetTable,
            targetColumns,
            isCreate: isCreate,
            isUpdate: isUpdate,
            isDelete: isDelete,
          );

          // Don't overwrite mutations that already exist
          final existingMutations = screenData['mutations'] as Map? ?? {};
          final mergedMutations =
              Map<String, dynamic>.from(existingMutations);
          for (final m in mutations.entries) {
            mergedMutations.putIfAbsent(m.key, () => m.value);
          }
          screenData['mutations'] = mergedMutations;

          // Remove builder-only metadata
          screenData.remove('table');
        }
      } else if (screenType == 'screen' || screenType == 'tab_screen') {
        // For non-form screens, if widget tree contains "delete_entry", add
        // delete mutation using the first table.
        if (_containsString(screenData, 'delete_entry') &&
            tableNames.isNotEmpty) {
          final firstKey = tableNames.keys.first;
          final firstTable = tableNames[firstKey]!;
          final firstColumns = _columnsForTable(tablesInput, firstKey);

          final deleteMutation = generateMutations(
            firstTable,
            firstColumns,
            isDelete: true,
          );

          final existingMutations = screenData['mutations'] as Map? ?? {};
          final mergedMutations =
              Map<String, dynamic>.from(existingMutations);
          for (final m in deleteMutation.entries) {
            mergedMutations.putIfAbsent(m.key, () => m.value);
          }
          screenData['mutations'] = mergedMutations;
        }
      }

      screens[screenId] = screenData;
    }

    // -- 3. Navigation --------------------------------------------------------
    ModuleNavigation? navigation;
    if (input['navigation'] != null) {
      navigation = ModuleNavigation.fromJson(
        Map<String, dynamic>.from(input['navigation'] as Map),
      );
    }

    // -- 4. Guide -------------------------------------------------------------
    List<Map<String, String>> guide = const [];
    if (input['guide'] != null) {
      guide = (input['guide'] as List)
          .cast<Map>()
          .map((m) => Map<String, String>.from(m))
          .toList();
    }

    // -- 5. Build Module ------------------------------------------------------
    final moduleId = _generateId();
    return Module(
      id: moduleId,
      name: name,
      description: description,
      icon: icon,
      color: color,
      screens: screens,
      database: ModuleDatabase(
        tableNames: tableNames,
        setup: setup,
        teardown: teardown,
      ),
      navigation: navigation,
      guide: guide,
    );
  }

  // ---------------------------------------------------------------------------
  // Build helpers
  // ---------------------------------------------------------------------------

  /// Extracts the column definitions for a given [schemaKey] from the raw
  /// tables input map.
  static List<Map<String, dynamic>> _columnsForTable(
    Map<String, dynamic> tablesInput,
    String schemaKey,
  ) {
    final tableData =
        Map<String, dynamic>.from(tablesInput[schemaKey] as Map);
    return (tableData['columns'] as List)
        .map((c) => Map<String, dynamic>.from(c as Map))
        .toList();
  }

  /// Recursively resolves `{{key}}` placeholders in all `sql` values found
  /// within a screen's `queries` map.
  static void _resolveQueriesInScreen(
    Map<String, dynamic> screen,
    Map<String, String> tableNames,
  ) {
    final queries = screen['queries'];
    if (queries == null) return;

    final queriesMap = Map<String, dynamic>.from(queries as Map);
    for (final key in queriesMap.keys) {
      final query = Map<String, dynamic>.from(queriesMap[key] as Map);
      if (query.containsKey('sql')) {
        query['sql'] = resolveTableReferences(
          query['sql'] as String,
          tableNames,
        );
      }
      queriesMap[key] = query;
    }
    screen['queries'] = queriesMap;
  }

  /// Returns `true` if the JSON-encoded representation of [data] contains
  /// [needle] anywhere. Used to detect action references like "delete_entry"
  /// in widget trees.
  static bool _containsString(Map<String, dynamic> data, String needle) {
    return jsonEncode(data).contains(needle);
  }

  /// Generates a unique module ID using the same pattern as
  /// `ChatActionExecutor._generateId()`.
  static String _generateId() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch;
    final hash =
        Object.hash(now, timestamp).toUnsigned(32).toRadixString(16);
    return '${timestamp}_$hash';
  }
}
