import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aj_assistant/core/models/entry.dart';
import 'package:aj_assistant/core/repositories/entry_repository.dart';
import 'package:aj_assistant/features/chat/bloc/chat_bloc.dart';
import 'package:aj_assistant/features/chat/bloc/chat_event.dart';
import 'package:aj_assistant/features/chat/bloc/chat_state.dart';
import 'package:aj_assistant/features/chat/models/message.dart';
import 'package:aj_assistant/features/chat/repositories/chat_repository.dart';

class MockChatRepository extends Mock implements ChatRepository {}

class MockEntryRepository extends Mock implements EntryRepository {}

class FakeEntry extends Fake implements Entry {}

void main() {
  late MockChatRepository chatRepo;
  late MockEntryRepository entryRepo;
  late StreamController<List<Message>> messagesController;

  const userId = 'test_user';
  const convId = 'conv_123';

  setUpAll(() {
    registerFallbackValue(FakeEntry());
  });

  setUp(() {
    chatRepo = MockChatRepository();
    entryRepo = MockEntryRepository();
    messagesController = StreamController<List<Message>>.broadcast();

    // Default stubs
    when(() => chatRepo.createConversation(any()))
        .thenAnswer((_) async => convId);

    when(() => chatRepo.watchMessages(any(), any()))
        .thenAnswer((_) => messagesController.stream);

    when(() => chatRepo.sendMessage(
          userId: any(named: 'userId'),
          conversationId: any(named: 'conversationId'),
          content: any(named: 'content'),
        )).thenAnswer((_) async => 'AI response');

    when(() => chatRepo.addLocalMessage(
          userId: any(named: 'userId'),
          conversationId: any(named: 'conversationId'),
          content: any(named: 'content'),
          role: any(named: 'role'),
        )).thenAnswer((_) async {});

    when(() => chatRepo.updateMessageApprovalStatus(
          userId: any(named: 'userId'),
          conversationId: any(named: 'conversationId'),
          messageId: any(named: 'messageId'),
          status: any(named: 'status'),
        )).thenAnswer((_) async {});

    when(() => entryRepo.createEntry(any(), any(), any()))
        .thenAnswer((_) async => 'new_entry_id');

    when(() => entryRepo.updateEntry(any(), any(), any()))
        .thenAnswer((_) async {});
  });

  tearDown(() {
    messagesController.close();
  });

  ChatBloc buildBloc() => ChatBloc(
        chatRepository: chatRepo,
        entryRepository: entryRepo,
        userId: userId,
      );

  group('ChatStarted', () {
    blocTest<ChatBloc, ChatState>(
      'creates conversation and emits ChatReady',
      build: buildBloc,
      act: (bloc) => bloc.add(const ChatStarted()),
      expect: () => [
        isA<ChatLoading>(),
        isA<ChatReady>()
            .having((s) => s.conversationId, 'conversationId', convId),
      ],
      verify: (_) {
        verify(() => chatRepo.createConversation(userId)).called(1);
        verify(() => chatRepo.watchMessages(userId, convId)).called(1);
      },
    );

    blocTest<ChatBloc, ChatState>(
      'emits error state when createConversation fails',
      build: () {
        when(() => chatRepo.createConversation(any()))
            .thenThrow(Exception('Network error'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const ChatStarted()),
      expect: () => [
        isA<ChatLoading>(),
        isA<ChatReady>()
            .having((s) => s.error, 'error', contains('Failed to start')),
      ],
    );
  });

  group('ChatMessageSent', () {
    blocTest<ChatBloc, ChatState>(
      'adds optimistic message and sets isAiTyping',
      build: buildBloc,
      seed: () => const ChatReady(conversationId: convId),
      act: (bloc) => bloc.add(const ChatMessageSent('Hello')),
      expect: () => [
        // Optimistic message + typing
        isA<ChatReady>()
            .having((s) => s.isAiTyping, 'isAiTyping', true)
            .having((s) => s.messages.length, 'messages.length', 1)
            .having(
              (s) => s.messages.first.content,
              'message content',
              'Hello',
            ),
        // Typing done
        isA<ChatReady>().having((s) => s.isAiTyping, 'isAiTyping', false),
      ],
      verify: (_) {
        verify(() => chatRepo.sendMessage(
              userId: userId,
              conversationId: convId,
              content: 'Hello',
            )).called(1);
      },
    );

    blocTest<ChatBloc, ChatState>(
      'shows friendly error on ChatException',
      build: () {
        when(() => chatRepo.sendMessage(
              userId: any(named: 'userId'),
              conversationId: any(named: 'conversationId'),
              content: any(named: 'content'),
            )).thenThrow(const ChatException('AJ is temporarily unavailable.'));
        return buildBloc();
      },
      seed: () => const ChatReady(conversationId: convId),
      act: (bloc) => bloc.add(const ChatMessageSent('Hi')),
      expect: () => [
        isA<ChatReady>().having((s) => s.isAiTyping, 'typing', true),
        isA<ChatReady>()
            .having((s) => s.isAiTyping, 'typing', false)
            .having(
              (s) => s.error,
              'error',
              'AJ is temporarily unavailable.',
            ),
      ],
    );

    blocTest<ChatBloc, ChatState>(
      'shows generic error on unexpected exception',
      build: () {
        when(() => chatRepo.sendMessage(
              userId: any(named: 'userId'),
              conversationId: any(named: 'conversationId'),
              content: any(named: 'content'),
            )).thenThrow(Exception('random crash'));
        return buildBloc();
      },
      seed: () => const ChatReady(conversationId: convId),
      act: (bloc) => bloc.add(const ChatMessageSent('Hi')),
      expect: () => [
        isA<ChatReady>().having((s) => s.isAiTyping, 'typing', true),
        isA<ChatReady>()
            .having((s) => s.isAiTyping, 'typing', false)
            .having(
              (s) => s.error,
              'error',
              'Something went wrong. Please try again.',
            ),
      ],
    );

    blocTest<ChatBloc, ChatState>(
      'clears previous error when sending new message',
      build: buildBloc,
      seed: () => const ChatReady(
        conversationId: convId,
        error: 'Previous error',
      ),
      act: (bloc) => bloc.add(const ChatMessageSent('Retry')),
      expect: () => [
        isA<ChatReady>()
            .having((s) => s.error, 'error cleared', isNull)
            .having((s) => s.isAiTyping, 'typing', true),
        isA<ChatReady>().having((s) => s.isAiTyping, 'typing', false),
      ],
    );

    blocTest<ChatBloc, ChatState>(
      'ignores MessageSent when not in ChatReady state',
      build: buildBloc,
      // Initial state is ChatInitial
      act: (bloc) => bloc.add(const ChatMessageSent('Hello')),
      expect: () => <ChatState>[],
    );
  });

  group('ChatMessagesUpdated', () {
    blocTest<ChatBloc, ChatState>(
      'updates messages in ChatReady',
      build: buildBloc,
      seed: () => const ChatReady(conversationId: convId),
      act: (bloc) => bloc.add(const ChatMessagesUpdated([
        Message(id: 'm1', role: MessageRole.user, content: 'Hi'),
        Message(id: 'm2', role: MessageRole.assistant, content: 'Hello!'),
      ])),
      expect: () => [
        isA<ChatReady>().having((s) => s.messages.length, 'len', 2),
      ],
    );
  });

  group('ChatActionApproved', () {
    final pendingMessages = [
      const Message(
        id: 'pending_msg',
        role: MessageRole.assistant,
        content: '',
        pendingActions: [
          PendingAction(
            toolUseId: 'tool_1',
            name: 'createEntry',
            input: {
              'moduleId': 'mod1',
              'schemaKey': 'expense',
              'data': {'amount': 50, 'note': 'test'},
            },
            description: 'Create expense',
          ),
        ],
      ),
    ];

    blocTest<ChatBloc, ChatState>(
      'executes create entry and marks approved',
      build: buildBloc,
      seed: () => ChatReady(
        conversationId: convId,
        messages: pendingMessages,
      ),
      act: (bloc) => bloc.add(const ChatActionApproved()),
      verify: (_) {
        // Verify approval status was set
        verify(() => chatRepo.updateMessageApprovalStatus(
              userId: userId,
              conversationId: convId,
              messageId: 'pending_msg',
              status: 'approved',
            )).called(1);

        // Verify entry was created
        verify(() => entryRepo.createEntry(userId, 'mod1', any())).called(1);

        // Verify confirmation message
        verify(() => chatRepo.addLocalMessage(
              userId: userId,
              conversationId: convId,
              content: any(named: 'content'),
              role: 'assistant',
            )).called(1);
      },
    );

    blocTest<ChatBloc, ChatState>(
      'handles entry creation failure gracefully',
      build: () {
        when(() => entryRepo.createEntry(any(), any(), any()))
            .thenThrow(Exception('Firestore error'));
        return buildBloc();
      },
      seed: () => ChatReady(
        conversationId: convId,
        messages: pendingMessages,
      ),
      act: (bloc) => bloc.add(const ChatActionApproved()),
      verify: (_) {
        // Still writes a confirmation (with error info)
        verify(() => chatRepo.addLocalMessage(
              userId: userId,
              conversationId: convId,
              content: any(named: 'content'),
              role: 'assistant',
            )).called(1);
      },
    );
  });

  group('ChatActionRejected', () {
    blocTest<ChatBloc, ChatState>(
      'marks as rejected and adds cancellation message',
      build: buildBloc,
      seed: () => const ChatReady(
        conversationId: convId,
        messages: [
          Message(
            id: 'pending_msg',
            role: MessageRole.assistant,
            content: '',
            pendingActions: [
              PendingAction(
                toolUseId: 'tool_1',
                name: 'createEntry',
                input: {},
                description: 'test',
              ),
            ],
          ),
        ],
      ),
      act: (bloc) => bloc.add(const ChatActionRejected()),
      verify: (_) {
        verify(() => chatRepo.updateMessageApprovalStatus(
              userId: userId,
              conversationId: convId,
              messageId: 'pending_msg',
              status: 'rejected',
            )).called(1);

        verify(() => chatRepo.addLocalMessage(
              userId: userId,
              conversationId: convId,
              content: 'Okay, cancelled.',
              role: 'assistant',
            )).called(1);
      },
    );
  });
}
