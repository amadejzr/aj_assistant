import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/ai/claude_client.dart' hide ChatEvent;
import '../../../core/ai/system_prompt.dart';
import '../../../core/ai/tool_definitions.dart';
import '../../../core/ai/tool_executor.dart';
import '../../../core/database/app_database.dart';
import '../../../core/logging/log.dart';
import '../../../core/models/module.dart';
import '../../../core/repositories/module_repository.dart';
import '../models/message.dart';
import '../services/chat_action_executor.dart';
import 'chat_event.dart';
import 'chat_state.dart';

const _tag = 'ChatBloc';
const _maxHistory = 20;
const _maxToolRounds = 10;

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ClaudeClient _claude;
  final AppDatabase _db;
  final ModuleRepository _moduleRepository;
  final String _userId;
  final ChatActionExecutor _actionExecutor;
  final ToolExecutor _toolExecutor;

  ChatBloc({
    required ClaudeClient claude,
    required AppDatabase db,
    required ModuleRepository moduleRepository,
    required String userId,
  })  : _claude = claude,
        _db = db,
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
        super(const ChatInitial()) {
    on<ChatStarted>(_onStarted);
    on<ChatMessageSent>(_onMessageSent);
    on<ChatStreamDelta>(_onStreamDelta);
    on<ChatStreamDone>(_onStreamDone);
    on<ChatActionApproved>(_onActionApproved);
    on<ChatActionRejected>(_onActionRejected);
  }

  Future<void> _onStarted(ChatStarted event, Emitter<ChatState> emit) async {
    emit(const ChatLoading());

    try {
      final conversationId =
          '${DateTime.now().millisecondsSinceEpoch}_${Object.hash(DateTime.now(), _userId).toUnsigned(32).toRadixString(16)}';
      final now = DateTime.now().millisecondsSinceEpoch;

      await _db.customInsert(
        'INSERT INTO conversations (id, created_at, last_message_at) VALUES (?, ?, ?)',
        variables: [Variable(conversationId), Variable(now), Variable(now)],
      );

      emit(ChatReady(conversationId: conversationId));
    } catch (e) {
      Log.e('Failed to start conversation: $e', tag: _tag);
      emit(ChatReady(error: 'Failed to start conversation: $e'));
    }
  }

  Future<void> _onMessageSent(
    ChatMessageSent event,
    Emitter<ChatState> emit,
  ) async {
    final current = state;
    if (current is! ChatReady || current.conversationId == null) return;

    // Save user message to Drift
    final msgId = '${DateTime.now().millisecondsSinceEpoch}_user';
    final now = DateTime.now().millisecondsSinceEpoch;

    await _db.customInsert(
      'INSERT INTO chat_messages (id, conversation_id, role, content, created_at) VALUES (?, ?, ?, ?, ?)',
      variables: [
        Variable(msgId),
        Variable(current.conversationId!),
        Variable('user'),
        Variable(event.text),
        Variable(now),
      ],
    );

    final userMsg = Message(
      id: msgId,
      role: MessageRole.user,
      content: event.text,
      timestamp: DateTime.fromMillisecondsSinceEpoch(now),
    );

    emit(current.copyWith(
      messages: [...current.messages, userMsg],
      isAiTyping: true,
      streamingText: '',
      clearError: true,
    ));

    try {
      final modules = await _moduleRepository.getModules(_userId);
      final systemPrompt = buildSystemPrompt(modules);

      final latest = state as ChatReady;
      final apiMessages = latest.messages
          .where((m) => m.content.isNotEmpty)
          .take(_maxHistory)
          .map((m) => m.toApiMessage())
          .toList();

      await _runToolLoop(emit, systemPrompt, apiMessages, modules);
    } catch (e) {
      Log.e('sendMessage failed: $e', tag: _tag);
      final latest = state;
      if (latest is ChatReady) {
        emit(latest.copyWith(
          isAiTyping: false,
          error: 'Something went wrong. Please try again.',
        ));
      }
    }
  }

  /// Runs the streaming tool loop: send to Claude, stream response,
  /// auto-execute read-only tools, pause for write tools.
  Future<void> _runToolLoop(
    Emitter<ChatState> emit,
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
      )) {
        switch (event) {
          case ChatTextDelta(:final text):
            fullText += text;
            add(ChatStreamDelta(text));

          case ChatToolUse():
            toolCalls.add(event);

          case ChatDone():
            break;

          case ChatError(:final message):
            Log.e('Stream error: $message', tag: _tag);
            final current = state;
            if (current is ChatReady) {
              emit(current.copyWith(isAiTyping: false, error: message));
            }
            return;
        }
      }

      // No tool calls — we're done
      if (toolCalls.isEmpty) {
        await _finalizeAssistantMessage(emit, fullText);
        return;
      }

      // Split read-only vs write tools
      final readTools =
          toolCalls.where((t) => ToolExecutor.isReadOnly(t.name)).toList();
      final writeTools =
          toolCalls.where((t) => !ToolExecutor.isReadOnly(t.name)).toList();

      if (writeTools.isNotEmpty) {
        if (fullText.isNotEmpty) {
          await _finalizeAssistantMessage(emit, fullText);
        }
        await _pauseForApproval(emit, writeTools, modules);
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

  Future<void> _finalizeAssistantMessage(
    Emitter<ChatState> emit,
    String text,
  ) async {
    final current = state;
    if (current is! ChatReady) return;

    final msgId = '${DateTime.now().millisecondsSinceEpoch}_assistant';
    final now = DateTime.now().millisecondsSinceEpoch;

    await _db.customInsert(
      'INSERT INTO chat_messages (id, conversation_id, role, content, created_at) VALUES (?, ?, ?, ?, ?)',
      variables: [
        Variable(msgId),
        Variable(current.conversationId!),
        Variable('assistant'),
        Variable(text),
        Variable(now),
      ],
    );

    final msg = Message(
      id: msgId,
      role: MessageRole.assistant,
      content: text,
      timestamp: DateTime.fromMillisecondsSinceEpoch(now),
    );

    emit(current.copyWith(
      messages: [...current.messages, msg],
      isAiTyping: false,
      streamingText: '',
    ));
  }

  Future<void> _pauseForApproval(
    Emitter<ChatState> emit,
    List<ChatToolUse> writeTools,
    List<Module> modules,
  ) async {
    final current = state;
    if (current is! ChatReady) return;

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

    final toolCallsJson = jsonEncode({
      'actions': actions.map((a) => a.toMap()).toList(),
      'approvalStatus': 'pending',
    });

    await _db.customInsert(
      'INSERT INTO chat_messages (id, conversation_id, role, content, tool_calls, created_at) VALUES (?, ?, ?, ?, ?, ?)',
      variables: [
        Variable(msgId),
        Variable(current.conversationId!),
        Variable('assistant'),
        Variable(''),
        Variable(toolCallsJson),
        Variable(now),
      ],
    );

    final msg = Message(
      id: msgId,
      role: MessageRole.assistant,
      content: '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(now),
      pendingActions: actions,
      approvalStatus: ApprovalStatus.pending,
    );

    emit(current.copyWith(
      messages: [...current.messages, msg],
      isAiTyping: false,
      streamingText: '',
    ));
  }

  void _onStreamDelta(ChatStreamDelta event, Emitter<ChatState> emit) {
    final current = state;
    if (current is! ChatReady) return;
    emit(current.copyWith(
      streamingText: current.streamingText + event.text,
    ));
  }

  void _onStreamDone(ChatStreamDone event, Emitter<ChatState> emit) {
    // Handled by _runToolLoop
  }

  Future<void> _onActionApproved(
    ChatActionApproved event,
    Emitter<ChatState> emit,
  ) async {
    final current = state;
    if (current is! ChatReady) return;

    final pendingMsg = current.messages.lastWhere(
      (m) => m.hasPendingActions && m.approvalStatus == ApprovalStatus.pending,
      orElse: () =>
          const Message(id: '', role: MessageRole.assistant, content: ''),
    );
    if (!pendingMsg.hasPendingActions) return;

    final updatedMessages = current.messages.map((m) {
      if (m.id == pendingMsg.id) {
        return m.copyWith(approvalStatus: ApprovalStatus.approved);
      }
      return m;
    }).toList();

    emit(current.copyWith(messages: updatedMessages, isAiTyping: true));

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
    await _finalizeAssistantMessage(emit, confirmation);
  }

  Future<void> _onActionRejected(
    ChatActionRejected event,
    Emitter<ChatState> emit,
  ) async {
    final current = state;
    if (current is! ChatReady) return;

    final pendingMsg = current.messages.lastWhere(
      (m) => m.hasPendingActions && m.approvalStatus == ApprovalStatus.pending,
      orElse: () =>
          const Message(id: '', role: MessageRole.assistant, content: ''),
    );

    if (pendingMsg.hasPendingActions) {
      final updatedMessages = current.messages.map((m) {
        if (m.id == pendingMsg.id) {
          return m.copyWith(approvalStatus: ApprovalStatus.rejected);
        }
        return m;
      }).toList();
      emit(current.copyWith(messages: updatedMessages));
    }

    await _finalizeAssistantMessage(emit, 'Okay, cancelled.');
  }
}
