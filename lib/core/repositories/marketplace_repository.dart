import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/module_template.dart';

abstract class MarketplaceRepository {
  Future<List<ModuleTemplate>> getTemplates();
  Future<ModuleTemplate?> getTemplate(String id);
  Future<void> incrementInstallCount(String id);
}

class FirestoreMarketplaceRepository implements MarketplaceRepository {
  final FirebaseFirestore _firestore;

  FirestoreMarketplaceRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _templatesRef =>
      _firestore.collection('marketplace_templates');

  @override
  Future<List<ModuleTemplate>> getTemplates() async {
    final snapshot = await _templatesRef.orderBy('sortOrder').get();
    return snapshot.docs.map(ModuleTemplate.fromFirestore).toList();
  }

  @override
  Future<ModuleTemplate?> getTemplate(String id) async {
    final doc = await _templatesRef.doc(id).get();
    if (!doc.exists) return null;
    return ModuleTemplate.fromFirestore(doc);
  }

  @override
  Future<void> incrementInstallCount(String id) async {
    await _templatesRef.doc(id).update({
      'installCount': FieldValue.increment(1),
    });
  }
}
