import 'package:equatable/equatable.dart';

class ChatConversation extends Equatable {
  final String id;
  final String? title;
  final String? preview;
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final int messageCount;

  const ChatConversation({
    required this.id,
    this.title,
    this.preview,
    required this.createdAt,
    required this.lastMessageAt,
    this.messageCount = 0,
  });

  String get displayTitle =>
      title ?? preview ?? 'New conversation';

  @override
  List<Object?> get props =>
      [id, title, preview, createdAt, lastMessageAt, messageCount];
}
