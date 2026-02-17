import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../../core/logging/log.dart';
import '../models/chat_context.dart';
import '../models/conversation.dart';
import '../models/message.dart';

const _tag = 'ChatRepo';

class ChatRepository {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  ChatRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'europe-west1');

  CollectionReference<Map<String, dynamic>> _conversationsRef(String userId) =>
      _firestore
          .collection('users')
          .doc(userId)
          .collection('conversations');

  CollectionReference<Map<String, dynamic>> _messagesRef(
    String userId,
    String conversationId,
  ) =>
      _conversationsRef(userId).doc(conversationId).collection('messages');

  Future<String> createConversation(
    String userId, {
    ChatContext? context,
  }) async {
    Log.d('Creating conversation for user=$userId', tag: _tag);
    final doc = _conversationsRef(userId).doc();
    await doc.set({
      if (context != null) 'context': context.toMap(),
      'startedAt': FieldValue.serverTimestamp(),
      'lastMessageAt': FieldValue.serverTimestamp(),
      'messageCount': 0,
    });
    Log.d('Conversation created: ${doc.id}', tag: _tag);
    return doc.id;
  }

  Stream<List<Message>> watchMessages(String userId, String conversationId) {
    Log.d('Watching messages: $conversationId', tag: _tag);
    return _messagesRef(userId, conversationId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) {
      final messages = snap.docs.map(Message.fromFirestore).toList();
      Log.d('Messages snapshot: ${messages.length} messages', tag: _tag);
      return messages;
    });
  }

  Future<String> sendMessage({
    required String userId,
    required String conversationId,
    required String content,
    ChatContext? context,
  }) async {
    Log.i('Calling chat function — conv=$conversationId', tag: _tag);
    final callable = _functions.httpsCallable(
      'chat',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 120)),
    );

    try {
      final result = await callable.call<Map<String, dynamic>>({
        'conversationId': conversationId,
        'message': content,
        if (context != null) 'context': context.toMap(),
      });

      final data = result.data;
      final message = data['message'] as String? ?? '';
      Log.i('Function returned: ${message.length} chars', tag: _tag);
      return message;
    } on FirebaseFunctionsException catch (e) {
      Log.e('Function error [${e.code}]: ${e.message}', tag: _tag);
      throw ChatException(_friendlyError(e.code, e.message));
    } catch (e) {
      Log.e('Function call failed: $e', tag: _tag);
      throw ChatException('Unable to reach AJ. Check your connection.');
    }
  }

  /// Write a local message to the conversation (no Cloud Function call).
  Future<void> addLocalMessage({
    required String userId,
    required String conversationId,
    required String content,
    required String role,
  }) async {
    Log.d('Adding local message ($role) to $conversationId', tag: _tag);
    await _messagesRef(userId, conversationId).add({
      'role': role,
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateMessageApprovalStatus({
    required String userId,
    required String conversationId,
    required String messageId,
    required String status,
  }) async {
    Log.d('Updating message $messageId approval=$status', tag: _tag);
    await _messagesRef(userId, conversationId).doc(messageId).update({
      'approvalStatus': status,
    });
  }

  Future<List<Conversation>> getRecentConversations(String userId) async {
    final snap = await _conversationsRef(userId)
        .orderBy('lastMessageAt', descending: true)
        .limit(10)
        .get();
    return snap.docs.map(Conversation.fromFirestore).toList();
  }

  static String _friendlyError(String code, String? message) {
    switch (code) {
      case 'unauthenticated':
        return 'Please sign in again to continue.';
      case 'unavailable':
        return 'AJ is temporarily unavailable. Please try again.';
      case 'deadline-exceeded':
        return 'Request timed out. Try a simpler message.';
      case 'resource-exhausted':
        return 'Too many requests. Please wait a moment.';
      case 'internal':
        return message ?? 'Something went wrong. Please try again.';
      default:
        return message ?? 'Something went wrong. Please try again.';
    }
  }
}

class ChatException implements Exception {
  final String message;
  const ChatException(this.message);

  @override
  String toString() => message;
}
