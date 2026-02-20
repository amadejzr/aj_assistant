import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../models/entry.dart';
import 'entry_repository.dart';

class DriftEntryRepository implements EntryRepository {
  final AppDatabase _db;

  DriftEntryRepository(this._db);

  @override
  Stream<List<Entry>> watchEntries(
    String userId,
    String moduleId, {
    String? schemaKey,
    String? orderBy,
    bool descending = true,
    int? limit,
  }) {
    var query = _db.select(_db.entries)
      ..where((t) => t.moduleId.equals(moduleId));

    if (schemaKey != null) {
      query = query..where((t) => t.schemaKey.equals(schemaKey));
    }

    query = query
      ..orderBy([
        (t) => OrderingTerm(
          expression: t.createdAt,
          mode: descending ? OrderingMode.desc : OrderingMode.asc,
        ),
      ]);

    if (limit != null) {
      query = query..limit(limit);
    }

    return query.watch().map((rows) => rows.map(_rowToEntry).toList());
  }

  @override
  Future<List<Entry>> getEntries(
    String userId,
    String moduleId, {
    String? schemaKey,
    String? orderBy,
    bool descending = true,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = _db.select(_db.entries)
      ..where((t) => t.moduleId.equals(moduleId));

    if (schemaKey != null) {
      query = query..where((t) => t.schemaKey.equals(schemaKey));
    }

    query = query
      ..orderBy([
        (t) => OrderingTerm(
          expression: t.createdAt,
          mode: descending ? OrderingMode.desc : OrderingMode.asc,
        ),
      ])
      ..limit(limit, offset: offset);

    final rows = await query.get();
    return rows.map(_rowToEntry).toList();
  }

  @override
  Future<int> countEntries(
    String userId,
    String moduleId, {
    String? schemaKey,
  }) async {
    final countExp = _db.entries.id.count();
    final query = _db.selectOnly(_db.entries)
      ..addColumns([countExp])
      ..where(_db.entries.moduleId.equals(moduleId));

    if (schemaKey != null) {
      query.where(_db.entries.schemaKey.equals(schemaKey));
    }

    final result = await query.getSingle();
    return result.read(countExp) ?? 0;
  }

  @override
  Future<String> createEntry(
    String userId,
    String moduleId,
    Entry entry,
  ) async {
    final id = entry.id.isEmpty
        ? '${DateTime.now().millisecondsSinceEpoch}_${Object().hashCode}'
        : entry.id;
    final now = DateTime.now().millisecondsSinceEpoch;

    await _db
        .into(_db.entries)
        .insert(
          EntriesCompanion.insert(
            id: id,
            moduleId: moduleId,
            schemaKey: Value(entry.schemaKey),
            data: entry.data,
            schemaVersion: Value(entry.schemaVersion),
            createdAt: now,
            updatedAt: now,
          ),
        );

    return id;
  }

  @override
  Future<void> updateEntry(String userId, String moduleId, Entry entry) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (_db.update(_db.entries)..where((t) => t.id.equals(entry.id))).write(
      EntriesCompanion(
        data: Value(entry.data),
        schemaKey: Value(entry.schemaKey),
        schemaVersion: Value(entry.schemaVersion),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<void> deleteEntry(
    String userId,
    String moduleId,
    String entryId,
  ) async {
    await (_db.delete(_db.entries)..where((t) => t.id.equals(entryId))).go();
  }

  Entry _rowToEntry(EntryRow row) {
    return Entry(
      id: row.id,
      data: row.data,
      schemaVersion: row.schemaVersion,
      schemaKey: row.schemaKey,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
    );
  }
}
