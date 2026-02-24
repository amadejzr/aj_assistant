import 'package:flutter_test/flutter_test.dart';
import 'package:bowerlab/features/chat/models/message.dart';

void main() {
  group('Message', () {
    test('creates user message', () {
      final msg = Message(
        id: '1',
        role: MessageRole.user,
        content: 'Hello',
        timestamp: DateTime(2026, 2, 23),
      );
      expect(msg.role, MessageRole.user);
      expect(msg.content, 'Hello');
      expect(msg.hasPendingActions, isFalse);
    });

    test('hasPendingActions returns true when actions present', () {
      const msg = Message(
        id: '1',
        role: MessageRole.assistant,
        content: '',
        pendingActions: [
          PendingAction(
            toolUseId: 'tool_1',
            name: 'createEntry',
            input: {'moduleId': 'test'},
            description: 'Create entry',
          ),
        ],
        approvalStatus: ApprovalStatus.pending,
      );
      expect(msg.hasPendingActions, isTrue);
    });

    test('toApiMessage formats user message', () {
      const msg = Message(
        id: '1',
        role: MessageRole.user,
        content: 'What are my expenses?',
      );
      final api = msg.toApiMessage();
      expect(api['role'], 'user');
      expect(api['content'], 'What are my expenses?');
    });

    test('toApiMessage formats assistant message', () {
      const msg = Message(
        id: '2',
        role: MessageRole.assistant,
        content: 'You have 5 expenses.',
      );
      final api = msg.toApiMessage();
      expect(api['role'], 'assistant');
      expect(api['content'], 'You have 5 expenses.');
    });

    test('copyWith updates approvalStatus', () {
      const msg = Message(
        id: '1',
        role: MessageRole.assistant,
        content: '',
        pendingActions: [
          PendingAction(
            toolUseId: 't1',
            name: 'createEntry',
            input: {},
            description: 'test',
          ),
        ],
        approvalStatus: ApprovalStatus.pending,
      );
      final updated = msg.copyWith(approvalStatus: ApprovalStatus.approved);
      expect(updated.approvalStatus, ApprovalStatus.approved);
      expect(updated.content, msg.content);
    });

    test('PendingAction.toMap roundtrips', () {
      const action = PendingAction(
        toolUseId: 't1',
        name: 'createEntry',
        input: {'moduleId': 'test', 'data': {'amount': 50}},
        description: 'Create entry',
      );
      final map = action.toMap();
      final restored = PendingAction.fromMap(map);
      expect(restored, action);
    });
  });
}
