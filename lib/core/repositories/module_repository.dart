import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/module.dart';

abstract class ModuleRepository {
  Stream<List<Module>> watchModules(String userId);
  Future<Module?> getModule(String userId, String moduleId);
  Future<void> createModule(String userId, Module module);
  Future<void> updateModule(String userId, Module module);
  Future<void> deleteModule(String userId, String moduleId);
}

class FirestoreModuleRepository implements ModuleRepository {
  final FirebaseFirestore _firestore;

  FirestoreModuleRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _modulesRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('modules');

  @override
  Stream<List<Module>> watchModules(String userId) {
    return _modulesRef(userId)
        .orderBy('sortOrder')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Module.fromFirestore).toList());
  }

  @override
  Future<Module?> getModule(String userId, String moduleId) async {
    final doc = await _modulesRef(userId).doc(moduleId).get();
    if (!doc.exists) return null;
    return Module.fromFirestore(doc);
  }

  @override
  Future<void> createModule(String userId, Module module) async {
    await _modulesRef(userId).doc(module.id).set(module.toFirestore());
  }

  @override
  Future<void> updateModule(String userId, Module module) async {
    await _modulesRef(userId).doc(module.id).update(module.toFirestore());
  }

  @override
  Future<void> deleteModule(String userId, String moduleId) async {
    await _modulesRef(userId).doc(moduleId).delete();
  }
}
