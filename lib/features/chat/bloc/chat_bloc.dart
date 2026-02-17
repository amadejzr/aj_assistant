import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/logging/log.dart';
import '../../../core/models/entry.dart';
import '../../../core/repositories/entry_repository.dart';
import '../models/message.dart';
import '../repositories/chat_repository.dart';
import 'chat_event.dart';
import 'chat_state.dart';

const _tag = 'ChatBloc';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _chatRepository;
  final EntryRepository _entryRepository;
  final String _userId;

  StreamSubscription<List<Message>>? _messagesSub;

  ChatBloc({
    required ChatRepository chatRepository,
    required EntryRepository entryRepository,
    required String userId,
  })  : _chatRepository = chatRepository,
        _entryRepository = entryRepository,
        _userId = userId,
        super(const ChatInitial()) {
    on<ChatStarted>(_onStarted);
    on<ChatMessageSent>(_onMessageSent);
    on<ChatActionApproved>(_onActionApproved);
    on<ChatActionRejected>(_onActionRejected);
    on<ChatContextChanged>(_onContextChanged);
    on<ChatMessagesUpdated>(_onMessagesUpdated);
  }

  Future<void> _onStarted(ChatStarted event, Emitter<ChatState> emit) async {
    Log.i('ChatStarted — creating conversation', tag: _tag);
    emit(const ChatLoading());

    try {
      final conversationId = await _chatRepository.createConversation(
        _userId,
        context: event.context,
      );
      Log.i('Conversation created: $conversationId', tag: _tag);

      await _messagesSub?.cancel();
      _messagesSub = _chatRepository
          .watchMessages(_userId, conversationId)
          .listen(
        (messages) {
          Log.d('Messages stream: ${messages.length} messages', tag: _tag);
          add(ChatMessagesUpdated(messages));
        },
        onError: (Object e) {
          Log.e('Messages stream error: $e', tag: _tag);
        },
      );

      emit(ChatReady(
        conversationId: conversationId,
        context: event.context,
      ));
    } catch (e, stack) {
      Log.e('Failed to start conversation: $e', tag: _tag);
      Log.e('$stack', tag: _tag);
      emit(ChatReady(error: 'Failed to start conversation: $e'));
    }
  }

  void _onMessagesUpdated(ChatMessagesUpdated event, Emitter<ChatState> emit) {
    final current = state;
    if (current is ChatReady) {
      emit(current.copyWith(messages: event.messages));
    }
  }

  Future<void> _onMessageSent(
    ChatMessageSent event,
    Emitter<ChatState> emit,
  ) async {
    final current = state;
    if (current is! ChatReady || current.conversationId == null) {
      Log.e('MessageSent but state is not ChatReady', tag: _tag);
      return;
    }

    Log.i('Sending message: "${event.text}"', tag: _tag);

    final optimisticMessage = Message(
      id: 'pending_${DateTime.now().millisecondsSinceEpoch}',
      role: MessageRole.user,
      content: event.text,
      timestamp: DateTime.now(),
    );

    emit(current.copyWith(
      messages: [...current.messages, optimisticMessage],
      isAiTyping: true,
      clearError: true,
    ));

    try {
      await _chatRepository.sendMessage(
        userId: _userId,
        conversationId: current.conversationId!,
        content: event.text,
        context: current.context,
      );

      final latest = state;
      if (latest is ChatReady) {
        emit(latest.copyWith(isAiTyping: false));
      }
    } catch (e, stack) {
      Log.e('sendMessage failed: $e', tag: _tag);
      Log.e('$stack', tag: _tag);
      final latest = state;
      if (latest is ChatReady) {
        emit(latest.copyWith(
          isAiTyping: false,
          error: 'Failed to send message: $e',
        ));
      }
    }
  }

  Future<void> _onActionApproved(
    ChatActionApproved event,
    Emitter<ChatState> emit,
  ) async {
    final current = state;
    if (current is! ChatReady || current.conversationId == null) return;

    // Find the pending actions from the latest message
    final pendingMsg = current.messages.lastWhere(
      (m) => m.hasPendingActions,
      orElse: () => const Message(id: '', role: MessageRole.assistant, content: ''),
    );
    if (!pendingMsg.hasPendingActions) return;

    Log.i('Approving ${pendingMsg.pendingActions.length} actions', tag: _tag);

    // Mark as approved in Firestore immediately so the card updates
    await _chatRepository.updateMessageApprovalStatus(
      userId: _userId,
      conversationId: current.conversationId!,
      messageId: pendingMsg.id,
      status: 'approved',
    );

    final results = <String>[];

    for (final action in pendingMsg.pendingActions) {
      try {
        switch (action.name) {
          case 'createEntry':
            final moduleId = action.input['moduleId'] as String;
            final schemaKey = action.input['schemaKey'] as String? ?? 'default';
            final data = Map<String, dynamic>.from(
              action.input['data'] as Map? ?? {},
            );
            final entry = Entry(
              id: '',
              data: data,
              schemaKey: schemaKey,
            );
            final id = await _entryRepository.createEntry(
              _userId, moduleId, entry,
            );
            Log.i('Created entry $id in $moduleId', tag: _tag);
            results.add('Created entry in $schemaKey');

          case 'updateEntry':
            final moduleId = action.input['moduleId'] as String;
            final entryId = action.input['entryId'] as String;
            final data = Map<String, dynamic>.from(
              action.input['data'] as Map? ?? {},
            );
            final entry = Entry(id: entryId, data: data);
            await _entryRepository.updateEntry(_userId, moduleId, entry);
            Log.i('Updated entry $entryId in $moduleId', tag: _tag);
            results.add('Updated entry');
        }
      } catch (e) {
        Log.e('Action ${action.name} failed: $e', tag: _tag);
        results.add('Failed: $e');
      }
    }

    // Write a confirmation message to the chat
    final confirmation = results.join('. ');
    await _chatRepository.addLocalMessage(
      userId: _userId,
      conversationId: current.conversationId!,
      content: 'Done. $confirmation.',
      role: 'assistant',
    );
  }

  Future<void> _onActionRejected(
    ChatActionRejected event,
    Emitter<ChatState> emit,
  ) async {
    final current = state;
    if (current is! ChatReady || current.conversationId == null) return;

    Log.i('User rejected actions', tag: _tag);

    // Find the pending actions message
    final pendingMsg = current.messages.lastWhere(
      (m) => m.hasPendingActions,
      orElse: () => const Message(id: '', role: MessageRole.assistant, content: ''),
    );

    if (pendingMsg.hasPendingActions) {
      await _chatRepository.updateMessageApprovalStatus(
        userId: _userId,
        conversationId: current.conversationId!,
        messageId: pendingMsg.id,
        status: 'rejected',
      );
    }

    await _chatRepository.addLocalMessage(
      userId: _userId,
      conversationId: current.conversationId!,
      content: 'Okay, cancelled.',
      role: 'assistant',
    );
  }

  void _onContextChanged(ChatContextChanged event, Emitter<ChatState> emit) {
    final current = state;
    if (current is ChatReady) {
      emit(current.copyWith(context: event.context));
    }
  }

  @override
  Future<void> close() {
    _messagesSub?.cancel();
    return super.close();
  }
}
