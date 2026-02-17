import 'package:flutter_test/flutter_test.dart';

import 'package:aj_assistant/features/chat/models/message.dart';

void main() {
  group('Message constructor and properties', () {
    test('basic user message', () {
      const msg = Message(
        id: 'msg1',
        role: MessageRole.user,
        content: 'Hello',
        timestamp: null,
      );
      expect(msg.id, 'msg1');
      expect(msg.role, MessageRole.user);
      expect(msg.content, 'Hello');
      expect(msg.hasPendingActions, false);
      expect(msg.approvalStatus, isNull);
    });

    test('assistant message', () {
      const msg = Message(
        id: 'msg2',
        role: MessageRole.assistant,
        content: 'Hi there!',
      );
      expect(msg.role, MessageRole.assistant);
      expect(msg.content, 'Hi there!');
    });

    test('message with pending actions', () {
      const msg = Message(
        id: 'msg3',
        role: MessageRole.assistant,
        content: '',
        pendingActions: [
          PendingAction(
            toolUseId: 'tool_1',
            name: 'createEntry',
            input: {'moduleId': 'mod1', 'data': {'amount': 50}},
            description: 'Create expense',
          ),
        ],
        approvalStatus: ApprovalStatus.pending,
      );
      expect(msg.hasPendingActions, true);
      expect(msg.pendingActions.length, 1);
      expect(msg.pendingActions[0].name, 'createEntry');
      expect(msg.pendingActions[0].toolUseId, 'tool_1');
      expect(msg.pendingActions[0].input['moduleId'], 'mod1');
      expect(msg.approvalStatus, ApprovalStatus.pending);
    });

    test('approved status', () {
      const msg = Message(
        id: 'msg4',
        role: MessageRole.assistant,
        content: '',
        approvalStatus: ApprovalStatus.approved,
      );
      expect(msg.approvalStatus, ApprovalStatus.approved);
    });

    test('rejected status', () {
      const msg = Message(
        id: 'msg5',
        role: MessageRole.assistant,
        content: '',
        approvalStatus: ApprovalStatus.rejected,
      );
      expect(msg.approvalStatus, ApprovalStatus.rejected);
    });

    test('empty message defaults', () {
      const msg = Message(
        id: 'msg6',
        role: MessageRole.user,
        content: '',
      );
      expect(msg.content, '');
      expect(msg.timestamp, isNull);
      expect(msg.pendingActions, isEmpty);
      expect(msg.hasPendingActions, false);
    });
  });

  group('PendingAction', () {
    test('fromMap parses correctly', () {
      final action = PendingAction.fromMap({
        'toolUseId': 'tool_x',
        'name': 'createEntry',
        'input': {'moduleId': 'mod1', 'data': {'amount': 100}},
        'description': 'Create expense: 100',
      });

      expect(action.toolUseId, 'tool_x');
      expect(action.name, 'createEntry');
      expect(action.input['moduleId'], 'mod1');
      expect(action.description, 'Create expense: 100');
    });

    test('fromMap handles missing fields', () {
      final action = PendingAction.fromMap({});
      expect(action.toolUseId, '');
      expect(action.name, '');
      expect(action.input, isEmpty);
      expect(action.description, '');
    });
  });

  group('Message equality', () {
    test('equal messages have same props', () {
      const m1 = Message(id: '1', role: MessageRole.user, content: 'hi');
      const m2 = Message(id: '1', role: MessageRole.user, content: 'hi');
      expect(m1, equals(m2));
    });

    test('different content means not equal', () {
      const m1 = Message(id: '1', role: MessageRole.user, content: 'hi');
      const m2 = Message(id: '1', role: MessageRole.user, content: 'bye');
      expect(m1, isNot(equals(m2)));
    });
  });
}
