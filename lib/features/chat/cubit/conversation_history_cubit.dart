import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/logging/log.dart';
import '../models/conversation.dart';
import '../repositories/chat_repository.dart';

const _tag = 'ConversationHistoryCubit';

class ConversationHistoryCubit extends Cubit<ConversationHistoryState> {
  final ChatRepository _repository;
  StreamSubscription<dynamic>? _subscription;

  ConversationHistoryCubit({required ChatRepository repository})
      : _repository = repository,
        super(const ConversationHistoryState());

  void start() {
    _subscription?.cancel();
    _subscription = _repository.watchConversations().listen(
      (conversations) => emit(state.copyWith(conversations: conversations)),
      onError: (Object error) {
        Log.e('Watch conversations error: $error', tag: _tag);
      },
    );
  }

  Future<String?> delete(String conversationId) async {
    try {
      await _repository.deleteConversation(conversationId);
      return null;
    } catch (e) {
      Log.e('Delete conversation failed: $e', tag: _tag);
      return 'Failed to delete conversation.';
    }
  }

  Future<String?> rename(String conversationId, String newTitle) async {
    try {
      await _repository.updateTitle(conversationId, newTitle);
      return null;
    } catch (e) {
      Log.e('Rename conversation failed: $e', tag: _tag);
      return 'Failed to rename conversation.';
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}

class ConversationHistoryState extends Equatable {
  final List<ChatConversation> conversations;

  const ConversationHistoryState({this.conversations = const []});

  ConversationHistoryState copyWith({List<ChatConversation>? conversations}) {
    return ConversationHistoryState(
      conversations: conversations ?? this.conversations,
    );
  }

  @override
  List<Object?> get props => [conversations];
}
