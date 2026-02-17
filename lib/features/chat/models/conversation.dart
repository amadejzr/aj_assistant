import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class Conversation extends Equatable {
  final String id;
  final Map<String, dynamic>? context;
  final DateTime? startedAt;
  final DateTime? lastMessageAt;
  final int messageCount;

  const Conversation({
    required this.id,
    this.context,
    this.startedAt,
    this.lastMessageAt,
    this.messageCount = 0,
  });

  factory Conversation.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return Conversation(
      id: doc.id,
      context: data['context'] as Map<String, dynamic>?,
      startedAt: _toDateTime(data['startedAt']),
      lastMessageAt: _toDateTime(data['lastMessageAt']),
      messageCount: data['messageCount'] as int? ?? 0,
    );
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  @override
  List<Object?> get props => [id, context, startedAt, lastMessageAt, messageCount];
}
