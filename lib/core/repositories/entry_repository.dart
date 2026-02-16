import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/entry.dart';

abstract class EntryRepository {
  Stream<List<Entry>> watchEntries(
    String userId,
    String moduleId, {
    String? orderBy,
    bool descending,
    int? limit,
  });

  Future<String> createEntry(String userId, String moduleId, Entry entry);
  Future<void> updateEntry(String userId, String moduleId, Entry entry);
  Future<void> deleteEntry(String userId, String moduleId, String entryId);
}

class FirestoreEntryRepository implements EntryRepository {
  final FirebaseFirestore _firestore;

  FirestoreEntryRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _entriesRef(
    String userId,
    String moduleId,
  ) =>
      _firestore
          .collection('users')
          .doc(userId)
          .collection('modules')
          .doc(moduleId)
          .collection('entries');

  @override
  Stream<List<Entry>> watchEntries(
    String userId,
    String moduleId, {
    String? orderBy,
    bool descending = true,
    int? limit,
  }) {
    Query<Map<String, dynamic>> query = _entriesRef(userId, moduleId);

    if (orderBy != null) {
      query = query.orderBy('data.$orderBy', descending: descending);
    } else {
      query = query.orderBy('createdAt', descending: descending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
          (snapshot) => snapshot.docs.map(Entry.fromFirestore).toList(),
        );
  }

  @override
  Future<String> createEntry(
    String userId,
    String moduleId,
    Entry entry,
  ) async {
    final docRef = _entriesRef(userId, moduleId).doc();
    await docRef.set(entry.toFirestore(isCreate: true));
    return docRef.id;
  }

  @override
  Future<void> updateEntry(
    String userId,
    String moduleId,
    Entry entry,
  ) async {
    await _entriesRef(userId, moduleId)
        .doc(entry.id)
        .update(entry.toFirestore());
  }

  @override
  Future<void> deleteEntry(
    String userId,
    String moduleId,
    String entryId,
  ) async {
    await _entriesRef(userId, moduleId).doc(entryId).delete();
  }
}
