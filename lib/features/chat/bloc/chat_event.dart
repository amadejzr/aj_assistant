import 'package:equatable/equatable.dart';

sealed class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

/// Open a new chat session.
class ChatStarted extends ChatEvent {
  const ChatStarted();
}

/// User sends a text message.
class ChatMessageSent extends ChatEvent {
  final String text;
  const ChatMessageSent(this.text);

  @override
  List<Object?> get props => [text];
}

/// User approved pending write actions.
class ChatActionApproved extends ChatEvent {
  const ChatActionApproved();
}

/// User rejected pending write actions.
class ChatActionRejected extends ChatEvent {
  const ChatActionRejected();
}

/// Internal: streaming text delta received.
class ChatStreamDelta extends ChatEvent {
  final String text;
  const ChatStreamDelta(this.text);

  @override
  List<Object?> get props => [text];
}

/// Internal: stream completed.
class ChatStreamDone extends ChatEvent {
  final String fullText;
  const ChatStreamDone(this.fullText);

  @override
  List<Object?> get props => [fullText];
}
