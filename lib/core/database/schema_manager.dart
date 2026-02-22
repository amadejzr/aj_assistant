import '../models/module.dart';
import 'app_database.dart';

/// Executes raw SQL from a module's [ModuleDatabase] definition.
///
/// The AI or marketplace writes the SQL (CREATE TABLE, triggers, indices).
/// This class just runs it.
class SchemaManager {
  final AppDatabase _db;

  SchemaManager({required AppDatabase db}) : _db = db;

  /// Installs a module's database — runs all setup SQL in order.
  ///
  /// Call this when a module is installed from marketplace or created via AI.
  Future<void> installModule(Module module) async {
    final database = module.database;
    if (database == null) return;

    await _db.customStatement('PRAGMA foreign_keys = ON');

    for (final sql in database.setup) {
      await _db.customStatement(sql);
    }
  }

  /// Uninstalls a module's database — runs all teardown SQL in order.
  Future<void> uninstallModule(Module module) async {
    final database = module.database;
    if (database == null) return;

    for (final sql in database.teardown) {
      await _db.customStatement(sql);
    }
  }

  /// Looks up which table to query for a given schema key.
  String? tableNameFor(Module module, String schemaKey) {
    return module.database?.tableNames[schemaKey];
  }
}
