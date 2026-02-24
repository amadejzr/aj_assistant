import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/ai/claude_client.dart';
import '../../../core/ai/system_prompt.dart';
import '../../../core/ai/tool_definitions.dart';
import '../../../core/ai/tool_executor.dart';
import '../../../core/database/app_database.dart';
import '../../../core/logging/log.dart';
import '../../../core/models/module.dart';
import '../../../core/repositories/module_repository.dart';
import '../models/message.dart';
import '../repositories/chat_repository.dart';
import '../services/chat_action_executor.dart';

const _tag = 'ChatCubit';
const _maxHistory = 20;
const _maxToolRounds = 10;
const _titleMaxLength = 50;

class ChatCubit extends Cubit<ChatState> {
  final ClaudeClient _claude;
  final ChatRepository _chatRepository;
  final ModuleRepository _moduleRepository;
  final String _userId;
  final ChatActionExecutor _actionExecutor;
  final ToolExecutor _toolExecutor;

  final String _model;
  bool _titleSet = false;

  ChatCubit({
    required ClaudeClient claude,
    required AppDatabase db,
    required ChatRepository chatRepository,
    required ModuleRepository moduleRepository,
    required String userId,
    required String model,
  })  : _claude = claude,
        _model = model,
        _chatRepository = chatRepository,
        _moduleRepository = moduleRepository,
        _userId = userId,
        _actionExecutor = ChatActionExecutor(
          db: db,
          moduleRepository: moduleRepository,
          userId: userId,
        ),
        _toolExecutor = ToolExecutor(
          db: db,
          moduleRepository: moduleRepository,
          userId: userId,
        ),
        super(const ChatState());

  void newConversation() {
    _titleSet = false;
    emit(const ChatState());
  }

  Future<void> resumeConversation(String conversationId) async {
    emit(state.copyWith(isLoading: true));

    try {
      final messages = await _chatRepository.getMessages(conversationId);
      _titleSet = true;
      emit(ChatState(conversationId: conversationId, messages: messages));
    } catch (e) {
      Log.e('Failed to resume conversation: $e', tag: _tag);
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to load conversation.',
      ));
    }
  }

  Future<void> sendMessage(String text) async {
    if (state.isAiTyping) return;

    // Lazily create conversation on first message
    var conversationId = state.conversationId;
    if (conversationId == null) {
      try {
        conversationId = await _chatRepository.createConversation();
      } catch (e) {
        Log.e('Failed to create conversation: $e', tag: _tag);
        emit(state.copyWith(error: 'Failed to start conversation.'));
        return;
      }
    }

    final msgId = '${DateTime.now().millisecondsSinceEpoch}_user';
    final now = DateTime.now().millisecondsSinceEpoch;

    final userMsg = Message(
      id: msgId,
      role: MessageRole.user,
      content: text,
      timestamp: DateTime.fromMillisecondsSinceEpoch(now),
    );

    await _chatRepository.saveMessage(conversationId, userMsg);
    await _chatRepository.updateLastMessageAt(conversationId);

    if (!_titleSet) {
      _titleSet = true;
      final title = text.length > _titleMaxLength
          ? '${text.substring(0, _titleMaxLength)}...'
          : text;
      await _chatRepository.updateTitle(conversationId, title);
    }

    emit(state.copyWith(
      conversationId: conversationId,
      messages: [...state.messages, userMsg],
      isAiTyping: true,
      streamingText: '',
      clearError: true,
    ));

    try {
      final modules = await _moduleRepository.getModules(_userId);
      final systemPrompt = buildSystemPrompt(modules);

      final apiMessages = state.messages
          .where((m) => m.content.isNotEmpty)
          .take(_maxHistory)
          .map((m) => m.toApiMessage())
          .toList();

      await _runToolLoop(systemPrompt, apiMessages, modules);
    } catch (e) {
      Log.e('sendMessage failed: $e', tag: _tag);
      emit(state.copyWith(
        isAiTyping: false,
        error: 'Something went wrong. Please try again.',
      ));
    }
  }

  Future<void> approveActions() async {
    final pendingMsg = state.messages.lastWhere(
      (m) => m.hasPendingActions && m.approvalStatus == ApprovalStatus.pending,
      orElse: () =>
          const Message(id: '', role: MessageRole.assistant, content: ''),
    );
    if (!pendingMsg.hasPendingActions) return;

    final updatedMessages = state.messages.map((m) {
      if (m.id == pendingMsg.id) {
        return m.copyWith(approvalStatus: ApprovalStatus.approved);
      }
      return m;
    }).toList();

    emit(state.copyWith(messages: updatedMessages, isAiTyping: true));

    await _chatRepository.updateApprovalStatus(
      pendingMsg.id,
      ApprovalStatus.approved,
    );

    final results = <String>[];
    for (final action in pendingMsg.pendingActions) {
      try {
        final result = await _actionExecutor.execute(action);
        results.add(result);
      } catch (e) {
        Log.e('Action ${action.name} failed: $e', tag: _tag);
        results.add('Failed: $e');
      }
    }

    final confirmation = 'Done. ${results.join('. ')}.';
    await _finalizeAssistantMessage(confirmation);
  }

  Future<void> rejectActions() async {
    final pendingMsg = state.messages.lastWhere(
      (m) => m.hasPendingActions && m.approvalStatus == ApprovalStatus.pending,
      orElse: () =>
          const Message(id: '', role: MessageRole.assistant, content: ''),
    );

    if (pendingMsg.hasPendingActions) {
      final updatedMessages = state.messages.map((m) {
        if (m.id == pendingMsg.id) {
          return m.copyWith(approvalStatus: ApprovalStatus.rejected);
        }
        return m;
      }).toList();
      emit(state.copyWith(messages: updatedMessages));

      await _chatRepository.updateApprovalStatus(
        pendingMsg.id,
        ApprovalStatus.rejected,
      );
    }

    await _finalizeAssistantMessage('Okay, cancelled.');
  }

  // -- Private helpers -------------------------------------------------------

  Future<void> _runToolLoop(
    String systemPrompt,
    List<Map<String, dynamic>> messages,
    List<Module> modules,
  ) async {
    final apiMessages = List<Map<String, dynamic>>.from(messages);

    for (var round = 0; round < _maxToolRounds; round++) {
      Log.i('Claude round ${round + 1}', tag: _tag);

      var fullText = '';
      final toolCalls = <ChatToolUse>[];

      await for (final event in _claude.stream(
        systemPrompt: systemPrompt,
        messages: apiMessages,
        tools: toolDefinitions,
        model: _model,
      )) {
        switch (event) {
          case ChatTextDelta(:final text):
            fullText += text;
            emit(state.copyWith(
              streamingText: state.streamingText + text,
            ));

          case ChatToolUse():
            toolCalls.add(event);

          case ChatDone():
            break;

          case ChatError(:final message):
            Log.e('Stream error: $message', tag: _tag);
            emit(state.copyWith(isAiTyping: false, error: message));
            return;
        }
      }

      if (toolCalls.isEmpty) {
        // Use accumulated streaming text (spans all tool rounds)
        final text = state.streamingText.isNotEmpty
            ? state.streamingText
            : fullText;
        await _finalizeAssistantMessage(text);
        return;
      }

      final readTools =
          toolCalls.where((t) => ToolExecutor.isReadOnly(t.name)).toList();
      final writeTools =
          toolCalls.where((t) => !ToolExecutor.isReadOnly(t.name)).toList();

      if (writeTools.isNotEmpty) {
        // Save accumulated streaming text before showing the approval card
        if (state.streamingText.isNotEmpty) {
          await _finalizeAssistantMessage(state.streamingText);
        }
        await _pauseForApproval(writeTools, modules);
        return;
      }

      // All read-only — execute and continue loop
      final assistantContent = <Map<String, dynamic>>[];
      if (fullText.isNotEmpty) {
        assistantContent.add({'type': 'text', 'text': fullText});
      }
      for (final tool in toolCalls) {
        assistantContent.add({
          'type': 'tool_use',
          'id': tool.id,
          'name': tool.name,
          'input': tool.input,
        });
      }
      apiMessages.add({'role': 'assistant', 'content': assistantContent});

      final toolResults = <Map<String, dynamic>>[];
      for (final tool in readTools) {
        final tableName = await _resolveTableForTool(tool, modules);
        final input = Map<String, dynamic>.from(tool.input);
        if (tableName != null) input['tableName'] = tableName;

        final result = await _toolExecutor.executeReadOnly(tool.name, input);
        toolResults.add({
          'type': 'tool_result',
          'tool_use_id': tool.id,
          'content': result,
        });
      }
      apiMessages.add({'role': 'user', 'content': toolResults});
    }
  }

  Future<String?> _resolveTableForTool(
    ChatToolUse tool,
    List<Module> modules,
  ) async {
    final moduleId = tool.input['moduleId'] as String?;
    if (moduleId == null) return null;

    final module = modules.where((m) => m.id == moduleId).firstOrNull;
    final schemaKey = tool.input['schemaKey'] as String? ?? 'default';
    return module?.database?.tableNames[schemaKey];
  }

  Future<void> _finalizeAssistantMessage(String text) async {
    final msgId = '${DateTime.now().millisecondsSinceEpoch}_assistant';
    final now = DateTime.now().millisecondsSinceEpoch;

    final msg = Message(
      id: msgId,
      role: MessageRole.assistant,
      content: text,
      timestamp: DateTime.fromMillisecondsSinceEpoch(now),
    );

    if (state.conversationId != null) {
      await _chatRepository.saveMessage(state.conversationId!, msg);
      await _chatRepository.updateLastMessageAt(state.conversationId!);
    }

    emit(state.copyWith(
      messages: [...state.messages, msg],
      isAiTyping: false,
      streamingText: '',
    ));
  }

  Future<void> _pauseForApproval(
    List<ChatToolUse> writeTools,
    List<Module> modules,
  ) async {
    final actions = writeTools
        .map((t) => PendingAction(
              toolUseId: t.id,
              name: t.name,
              input: t.input,
              description: describeAction(t.name, t.input),
            ))
        .toList();

    final msgId = '${DateTime.now().millisecondsSinceEpoch}_approval';
    final now = DateTime.now().millisecondsSinceEpoch;

    final msg = Message(
      id: msgId,
      role: MessageRole.assistant,
      content: '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(now),
      pendingActions: actions,
      approvalStatus: ApprovalStatus.pending,
    );

    if (state.conversationId != null) {
      await _chatRepository.saveMessage(state.conversationId!, msg);
    }

    emit(state.copyWith(
      messages: [...state.messages, msg],
      isAiTyping: false,
      streamingText: '',
    ));
  }
}

class ChatState extends Equatable {
  final List<Message> messages;
  final bool isAiTyping;
  final bool isLoading;
  final String streamingText;
  final String? conversationId;
  final String? error;

  const ChatState({
    this.messages = const [],
    this.isAiTyping = false,
    this.isLoading = false,
    this.streamingText = '',
    this.conversationId,
    this.error,
  });

  ChatState copyWith({
    List<Message>? messages,
    bool? isAiTyping,
    bool? isLoading,
    String? streamingText,
    String? conversationId,
    String? error,
    bool clearError = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isAiTyping: isAiTyping ?? this.isAiTyping,
      isLoading: isLoading ?? false,
      streamingText: streamingText ?? this.streamingText,
      conversationId: conversationId ?? this.conversationId,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props =>
      [messages, isAiTyping, isLoading, streamingText, conversationId, error];
}
