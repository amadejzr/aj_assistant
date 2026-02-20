import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../models/capability.dart';
import 'capability_repository.dart';

class DriftCapabilityRepository implements CapabilityRepository {
  final AppDatabase _db;

  DriftCapabilityRepository(this._db);

  @override
  Stream<List<Capability>> watchCapabilities(String moduleId) {
    final query = _db.select(_db.capabilities)
      ..where((t) => t.moduleId.equals(moduleId))
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
    return query.watch().map((rows) => rows.map(_rowToCapability).toList());
  }

  @override
  Stream<List<Capability>> watchAllCapabilities() {
    final query = _db.select(_db.capabilities)
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
    return query.watch().map((rows) => rows.map(_rowToCapability).toList());
  }

  @override
  Stream<List<Capability>> watchEnabledCapabilities({int? limit}) {
    final query = _db.select(_db.capabilities)
      ..where((t) => t.enabled.equals(true))
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
    if (limit != null) query.limit(limit);
    return query.watch().map((rows) => rows.map(_rowToCapability).toList());
  }

  @override
  Future<List<Capability>> getCapabilities(String moduleId) async {
    final query = _db.select(_db.capabilities)
      ..where((t) => t.moduleId.equals(moduleId))
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
    final rows = await query.get();
    return rows.map(_rowToCapability).toList();
  }

  @override
  Future<List<Capability>> getAllEnabledCapabilities() async {
    final query = _db.select(_db.capabilities)
      ..where((t) => t.enabled.equals(true));
    final rows = await query.get();
    return rows.map(_rowToCapability).toList();
  }

  @override
  Future<Capability?> getCapability(String id) async {
    final query = _db.select(_db.capabilities)
      ..where((t) => t.id.equals(id));
    final row = await query.getSingleOrNull();
    return row == null ? null : _rowToCapability(row);
  }

  @override
  Future<void> createCapability(Capability capability) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.into(_db.capabilities).insert(
      CapabilitiesCompanion.insert(
        id: capability.id,
        moduleId: Value(capability.moduleId),
        type: capability.type,
        title: capability.title,
        message: capability.message,
        config: Value(capability.configToJson()),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  @override
  Future<void> updateCapability(Capability capability) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (_db.update(_db.capabilities)
          ..where((t) => t.id.equals(capability.id)))
        .write(
      CapabilitiesCompanion(
        title: Value(capability.title),
        message: Value(capability.message),
        enabled: Value(capability.enabled),
        config: Value(capability.configToJson()),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<void> toggleCapability(String id, bool enabled) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (_db.update(_db.capabilities)..where((t) => t.id.equals(id))).write(
      CapabilitiesCompanion(
        enabled: Value(enabled),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<void> deleteCapability(String id) async {
    await (_db.delete(_db.capabilities)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<void> deleteAllForModule(String moduleId) async {
    await (_db.delete(_db.capabilities)
          ..where((t) => t.moduleId.equals(moduleId)))
        .go();
  }

  @override
  Future<void> updateLastFiredAt(String id, DateTime firedAt) async {
    await (_db.update(_db.capabilities)..where((t) => t.id.equals(id))).write(
      CapabilitiesCompanion(
        lastFiredAt: Value(firedAt.millisecondsSinceEpoch),
      ),
    );
  }

  Capability _rowToCapability(CapabilityRow row) {
    final json = {
      if (row.moduleId != null) 'moduleId': row.moduleId,
      'type': row.type,
      'title': row.title,
      'message': row.message,
      'enabled': row.enabled,
      'config': row.config,
      if (row.lastFiredAt != null) 'lastFiredAt': row.lastFiredAt,
      'createdAt': row.createdAt,
      'updatedAt': row.updatedAt,
    };
    return Capability.fromJson(row.id, json);
  }
}
