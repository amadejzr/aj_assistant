import '../models/entry.dart';

abstract class EntryRepository {
  /// Reactive stream of entries. Used by BLoCs for live updates.
  Stream<List<Entry>> watchEntries(
    String userId,
    String moduleId, {
    String? schemaKey,
    String? orderBy,
    bool descending,
    int? limit,
  });

  /// Paginated fetch. Used by "view all" screens.
  Future<List<Entry>> getEntries(
    String userId,
    String moduleId, {
    String? schemaKey,
    String? orderBy,
    bool descending,
    int limit,
    int offset,
  });

  /// Total count for a module (optionally filtered by schema key).
  Future<int> countEntries(String userId, String moduleId, {String? schemaKey});

  Future<String> createEntry(String userId, String moduleId, Entry entry);
  Future<void> updateEntry(String userId, String moduleId, Entry entry);
  Future<void> deleteEntry(String userId, String moduleId, String entryId);
}
