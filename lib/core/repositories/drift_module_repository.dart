import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../models/module.dart';
import 'module_repository.dart';

class DriftModuleRepository implements ModuleRepository {
  final AppDatabase _db;

  DriftModuleRepository(this._db);

  @override
  Stream<List<Module>> watchModules(String userId) {
    final query = _db.select(_db.modules)
      ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]);
    return query.watch().map((rows) => rows.map(_rowToModule).toList());
  }

  @override
  Future<Module?> getModule(String userId, String moduleId) async {
    final query = _db.select(_db.modules)..where((t) => t.id.equals(moduleId));
    final row = await query.getSingleOrNull();
    return row == null ? null : _rowToModule(row);
  }

  @override
  Future<void> createModule(String userId, Module module) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db
        .into(_db.modules)
        .insert(
          ModulesCompanion.insert(
            id: module.id,
            name: module.name,
            description: Value(module.description),
            icon: Value(module.icon),
            color: Value(module.color),
            sortOrder: Value(module.sortOrder),
            schemas: module.schemas,
            screens: module.screens,
            settings: Value(module.settings),
            guide: Value(module.guide),
            navigation: Value(module.navigation),
            version: Value(module.version),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  @override
  Future<void> updateModule(String userId, Module module) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (_db.update(_db.modules)..where((t) => t.id.equals(module.id))).write(
      ModulesCompanion(
        name: Value(module.name),
        description: Value(module.description),
        icon: Value(module.icon),
        color: Value(module.color),
        sortOrder: Value(module.sortOrder),
        schemas: Value(module.schemas),
        screens: Value(module.screens),
        settings: Value(module.settings),
        guide: Value(module.guide),
        navigation: Value(module.navigation),
        version: Value(module.version),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<void> deleteModule(String userId, String moduleId) async {
    await _db.transaction(() async {
      // Delete all entries belonging to this module first
      await (_db.delete(_db.entries)
            ..where((t) => t.moduleId.equals(moduleId)))
          .go();
      await (_db.delete(_db.modules)
            ..where((t) => t.id.equals(moduleId)))
          .go();
    });
  }

  Module _rowToModule(ModuleRow row) {
    return Module(
      id: row.id,
      name: row.name,
      description: row.description,
      icon: row.icon,
      color: row.color,
      sortOrder: row.sortOrder,
      schemas: row.schemas,
      screens: row.screens,
      settings: row.settings,
      guide: row.guide,
      version: row.version,
      navigation: row.navigation,
    );
  }
}
