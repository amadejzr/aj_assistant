import 'package:equatable/equatable.dart';

import '../models/chat_context.dart';
import '../models/message.dart';

sealed class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {
  const ChatInitial();
}

class ChatLoading extends ChatState {
  const ChatLoading();
}

class ChatReady extends ChatState {
  final List<Message> messages;
  final bool isAiTyping;
  final String? conversationId;
  final ChatContext? context;
  final String? error;

  const ChatReady({
    this.messages = const [],
    this.isAiTyping = false,
    this.conversationId,
    this.context,
    this.error,
  });

  ChatReady copyWith({
    List<Message>? messages,
    bool? isAiTyping,
    String? conversationId,
    ChatContext? context,
    String? error,
    bool clearError = false,
  }) {
    return ChatReady(
      messages: messages ?? this.messages,
      isAiTyping: isAiTyping ?? this.isAiTyping,
      conversationId: conversationId ?? this.conversationId,
      context: context ?? this.context,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [messages, isAiTyping, conversationId, context, error];
}
