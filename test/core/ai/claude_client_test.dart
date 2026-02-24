import 'package:flutter_test/flutter_test.dart';
import 'package:bowerlab/core/ai/claude_client.dart';

void main() {
  group('ChatEvent', () {
    test('ChatTextDelta holds text', () {
      const event = ChatTextDelta('Hello');
      expect(event.text, 'Hello');
    });

    test('ChatToolUse holds tool call data', () {
      const event = ChatToolUse(
        id: 'tool_1',
        name: 'queryEntries',
        input: {'moduleId': 'test'},
      );
      expect(event.name, 'queryEntries');
      expect(event.input['moduleId'], 'test');
    });

    test('ChatDone holds full text', () {
      const event = ChatDone('Full response');
      expect(event.fullText, 'Full response');
    });

    test('ChatError holds message', () {
      const event = ChatError('API failed');
      expect(event.message, 'API failed');
    });
  });

  group('parseSseEvent', () {
    test('parses content_block_delta text', () {
      final event = parseSseEvent(
        'content_block_delta',
        '{"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"Hello"}}',
      );
      expect(event, isA<ChatTextDelta>());
      expect((event as ChatTextDelta).text, 'Hello');
    });

    test('parses error event', () {
      final event = parseSseEvent(
        'error',
        '{"type":"error","error":{"type":"overloaded_error","message":"Overloaded"}}',
      );
      expect(event, isA<ChatError>());
      expect((event as ChatError).message, 'Overloaded');
    });

    test('returns null for unknown events', () {
      final event = parseSseEvent('ping', '{}');
      expect(event, isNull);
    });

    test('returns null for invalid JSON', () {
      final event = parseSseEvent('content_block_delta', 'not json');
      expect(event, isNull);
    });

    test('returns null for content_block_start', () {
      final event = parseSseEvent(
        'content_block_start',
        '{"type":"content_block_start","content_block":{"type":"text"}}',
      );
      expect(event, isNull);
    });
  });
}
