import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class Entry extends Equatable {
  final String id;
  final Map<String, dynamic> data;
  final int schemaVersion;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Entry({
    required this.id,
    required this.data,
    this.schemaVersion = 1,
    this.createdAt,
    this.updatedAt,
  });

  factory Entry.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final raw = doc.data() ?? {};
    return Entry(
      id: doc.id,
      data: Map<String, dynamic>.from(raw['data'] as Map? ?? {}),
      schemaVersion: raw['schemaVersion'] as int? ?? 1,
      createdAt: _toDateTime(raw['createdAt']),
      updatedAt: _toDateTime(raw['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore({bool isCreate = false}) {
    return {
      'data': data,
      'schemaVersion': schemaVersion,
      if (isCreate) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  @override
  List<Object?> get props => [id, data, schemaVersion, createdAt, updatedAt];
}
