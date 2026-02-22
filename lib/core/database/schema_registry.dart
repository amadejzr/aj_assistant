/// In-memory registry tracking dynamic module tables and their columns.
///
/// Used by [SchemaManager] for DDL operations and by query builders
/// to validate table/column names before generating SQL.
class SchemaRegistry {
  final Map<String, _TableEntry> _tables = {};

  /// Registers a module's table name and column definitions.
  void register({
    required String moduleId,
    required String tableName,
    required Map<String, String> columns,
  }) {
    _tables[moduleId] = _TableEntry(tableName, Map.of(columns));
  }

  /// Removes a module's registration.
  void unregister(String moduleId) {
    _tables.remove(moduleId);
  }

  /// Adds a column to an existing registration.
  void addColumn(String moduleId, String columnName, String sqlType) {
    _tables[moduleId]?.columns[columnName] = sqlType;
  }

  /// Whether a table is registered for [moduleId].
  bool hasTable(String moduleId) => _tables.containsKey(moduleId);

  /// Returns the table name for [moduleId], or null if not registered.
  String? getTableName(String moduleId) => _tables[moduleId]?.tableName;

  /// Returns the column map for [moduleId], or null if not registered.
  Map<String, String>? getColumns(String moduleId) =>
      _tables[moduleId]?.columns;

  /// Whether [columnName] is a registered column for [moduleId].
  bool isValidColumn(String moduleId, String columnName) =>
      _tables[moduleId]?.columns.containsKey(columnName) ?? false;

  /// All currently registered module IDs.
  Iterable<String> get registeredModuleIds => _tables.keys;
}

class _TableEntry {
  final String tableName;
  final Map<String, String> columns;

  _TableEntry(this.tableName, this.columns);
}
