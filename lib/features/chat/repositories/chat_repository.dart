import '../models/conversation.dart';
import '../models/message.dart';

abstract class ChatRepository {
  Stream<List<ChatConversation>> watchConversations();

  Future<String> createConversation();

  Future<void> updateTitle(String id, String title);

  Future<void> deleteConversation(String id);

  Future<List<Message>> getMessages(String conversationId);

  Future<void> saveMessage(String conversationId, Message message);

  Future<void> updateLastMessageAt(String conversationId);

  Future<void> updateApprovalStatus(String messageId, ApprovalStatus status);
}
