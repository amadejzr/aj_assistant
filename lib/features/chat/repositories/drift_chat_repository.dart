import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import 'chat_repository.dart';

class DriftChatRepository implements ChatRepository {
  final AppDatabase _db;

  DriftChatRepository(this._db);

  @override
  Stream<List<ChatConversation>> watchConversations() {
    final query = _db.customSelect(
      '''
      SELECT c.id, c.title, c.created_at, c.last_message_at,
        (SELECT COUNT(*) FROM chat_messages WHERE conversation_id = c.id) AS message_count,
        (SELECT content FROM chat_messages
         WHERE conversation_id = c.id AND role = 'user'
         ORDER BY created_at ASC LIMIT 1) AS preview
      FROM conversations c
      ORDER BY c.last_message_at DESC
      ''',
      readsFrom: {_db.conversations, _db.chatMessages},
    );

    return query.watch().map((rows) => rows.map((row) {
          final data = row.data;
          return ChatConversation(
            id: data['id'] as String,
            title: data['title'] as String?,
            preview: _truncate(data['preview'] as String?, 60),
            createdAt: DateTime.fromMillisecondsSinceEpoch(
              data['created_at'] as int,
            ),
            lastMessageAt: DateTime.fromMillisecondsSinceEpoch(
              data['last_message_at'] as int,
            ),
            messageCount: data['message_count'] as int,
          );
        }).toList());
  }

  @override
  Future<String> createConversation() async {
    final id =
        '${DateTime.now().millisecondsSinceEpoch}_${Object.hash(DateTime.now(), 'conv').toUnsigned(32).toRadixString(16)}';
    final now = DateTime.now().millisecondsSinceEpoch;

    await _db.customInsert(
      'INSERT INTO conversations (id, created_at, last_message_at) VALUES (?, ?, ?)',
      variables: [Variable(id), Variable(now), Variable(now)],
    );

    return id;
  }

  @override
  Future<void> updateTitle(String id, String title) async {
    await _db.customUpdate(
      'UPDATE conversations SET title = ? WHERE id = ?',
      variables: [Variable(title), Variable(id)],
      updates: {_db.conversations},
    );
  }

  @override
  Future<void> deleteConversation(String id) async {
    await _db.transaction(() async {
      await _db.customUpdate(
        'DELETE FROM chat_messages WHERE conversation_id = ?',
        variables: [Variable(id)],
        updates: {_db.chatMessages},
      );
      await _db.customUpdate(
        'DELETE FROM conversations WHERE id = ?',
        variables: [Variable(id)],
        updates: {_db.conversations},
      );
    });
  }

  @override
  Future<List<Message>> getMessages(String conversationId) async {
    final rows = await _db.customSelect(
      'SELECT * FROM chat_messages WHERE conversation_id = ? ORDER BY created_at ASC',
      variables: [Variable(conversationId)],
      readsFrom: {_db.chatMessages},
    ).get();

    return rows.map((row) => Message.fromRow(row.data)).toList();
  }

  @override
  Future<void> saveMessage(String conversationId, Message message) async {
    final now = message.timestamp?.millisecondsSinceEpoch ??
        DateTime.now().millisecondsSinceEpoch;

    String? toolCallsJson;
    if (message.hasPendingActions) {
      toolCallsJson = jsonEncode({
        'actions': message.pendingActions.map((a) => a.toMap()).toList(),
        'approvalStatus': message.approvalStatus?.name ?? 'pending',
      });
    }

    await _db.customInsert(
      'INSERT INTO chat_messages (id, conversation_id, role, content, tool_calls, created_at) VALUES (?, ?, ?, ?, ?, ?)',
      variables: [
        Variable(message.id),
        Variable(conversationId),
        Variable(message.role == MessageRole.user ? 'user' : 'assistant'),
        Variable(message.content),
        Variable(toolCallsJson),
        Variable(now),
      ],
    );
  }

  @override
  Future<void> updateLastMessageAt(String conversationId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.customUpdate(
      'UPDATE conversations SET last_message_at = ? WHERE id = ?',
      variables: [Variable(now), Variable(conversationId)],
      updates: {_db.conversations},
    );
  }

  @override
  Future<void> updateApprovalStatus(
    String messageId,
    ApprovalStatus status,
  ) async {
    final rows = await _db.customSelect(
      'SELECT tool_calls FROM chat_messages WHERE id = ?',
      variables: [Variable(messageId)],
      readsFrom: {_db.chatMessages},
    ).get();

    if (rows.isEmpty) return;

    final existing = rows.first.data['tool_calls'] as String?;
    if (existing == null) return;

    final decoded = jsonDecode(existing) as Map<String, dynamic>;
    decoded['approvalStatus'] = status.name;

    await _db.customUpdate(
      'UPDATE chat_messages SET tool_calls = ? WHERE id = ?',
      variables: [Variable(jsonEncode(decoded)), Variable(messageId)],
      updates: {_db.chatMessages},
    );
  }

  String? _truncate(String? text, int maxLength) {
    if (text == null) return null;
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}
