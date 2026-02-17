import 'package:equatable/equatable.dart';

import '../models/chat_context.dart';
import '../models/message.dart';

sealed class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

/// Open / resume a chat session.
class ChatStarted extends ChatEvent {
  final ChatContext? context;
  const ChatStarted({this.context});

  @override
  List<Object?> get props => [context];
}

/// User sends a text message.
class ChatMessageSent extends ChatEvent {
  final String text;
  const ChatMessageSent(this.text);

  @override
  List<Object?> get props => [text];
}

/// The module/screen context changed (user navigated).
class ChatContextChanged extends ChatEvent {
  final ChatContext context;
  const ChatContextChanged(this.context);

  @override
  List<Object?> get props => [context];
}

/// User approved pending actions.
class ChatActionApproved extends ChatEvent {
  const ChatActionApproved();
}

/// User rejected pending actions.
class ChatActionRejected extends ChatEvent {
  const ChatActionRejected();
}

/// Internal: real-time message stream updated.
class ChatMessagesUpdated extends ChatEvent {
  final List<Message> messages;
  const ChatMessagesUpdated(this.messages);

  @override
  List<Object?> get props => [messages];
}
