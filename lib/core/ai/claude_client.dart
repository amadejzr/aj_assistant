import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../logging/log.dart';

const _tag = 'ClaudeClient';
const _apiUrl = 'https://api.anthropic.com/v1/messages';
const _model = 'claude-sonnet-4-5-20250929';
const _maxTokens = 4096;
const _apiVersion = '2023-06-01';

// ─── Chat Events ───

sealed class ChatEvent {
  const ChatEvent();
}

class ChatTextDelta extends ChatEvent {
  final String text;
  const ChatTextDelta(this.text);
}

class ChatToolUse extends ChatEvent {
  final String id;
  final String name;
  final Map<String, dynamic> input;
  const ChatToolUse({
    required this.id,
    required this.name,
    required this.input,
  });
}

class ChatDone extends ChatEvent {
  final String fullText;
  const ChatDone(this.fullText);
}

class ChatError extends ChatEvent {
  final String message;
  const ChatError(this.message);
}

// ─── SSE Parsing ───

ChatEvent? parseSseEvent(String eventType, String data) {
  try {
    final json = jsonDecode(data) as Map<String, dynamic>;

    switch (eventType) {
      case 'content_block_delta':
        final delta = json['delta'] as Map<String, dynamic>?;
        if (delta == null) return null;
        if (delta['type'] == 'text_delta') {
          return ChatTextDelta(delta['text'] as String? ?? '');
        }
        return null;

      case 'error':
        final error = json['error'] as Map<String, dynamic>?;
        return ChatError(error?['message'] as String? ?? 'Unknown error');

      default:
        return null;
    }
  } catch (e) {
    return null;
  }
}

// ─── Client ───

class ClaudeClient {
  final String apiKey;
  final HttpClient _httpClient;

  ClaudeClient({required this.apiKey, HttpClient? httpClient})
      : _httpClient = httpClient ?? HttpClient();

  /// Streams a single Claude API call. Handles SSE parsing, text deltas,
  /// and tool_use block accumulation.
  Stream<ChatEvent> stream({
    required String systemPrompt,
    required List<Map<String, dynamic>> messages,
    required List<Map<String, dynamic>> tools,
  }) async* {
    final body = jsonEncode({
      'model': _model,
      'max_tokens': _maxTokens,
      'system': systemPrompt,
      'messages': messages,
      'tools': tools,
      'stream': true,
    });

    HttpClientRequest request;
    try {
      request = await _httpClient.postUrl(Uri.parse(_apiUrl));
    } catch (e) {
      Log.e('Failed to connect', tag: _tag, error: e);
      yield ChatError('Failed to connect: $e');
      return;
    }

    request.headers.set('Content-Type', 'application/json');
    request.headers.set('x-api-key', apiKey);
    request.headers.set('anthropic-version', _apiVersion);
    request.write(body);

    HttpClientResponse response;
    try {
      response = await request.close();
    } catch (e) {
      Log.e('Request failed', tag: _tag, error: e);
      yield ChatError('Request failed: $e');
      return;
    }

    if (response.statusCode != 200) {
      final errorBody = await response.transform(utf8.decoder).join();
      try {
        final errorJson = jsonDecode(errorBody) as Map<String, dynamic>;
        final error = errorJson['error'] as Map<String, dynamic>?;
        final message =
            error?['message'] as String? ?? 'HTTP ${response.statusCode}';
        Log.e('API error: $message', tag: _tag);
        yield ChatError(message);
      } catch (_) {
        Log.e('HTTP ${response.statusCode}: $errorBody', tag: _tag);
        yield ChatError('HTTP ${response.statusCode}: $errorBody');
      }
      return;
    }

    // Parse SSE stream
    var fullText = '';
    var currentToolId = '';
    var currentToolName = '';
    var toolInputJson = '';

    await for (final chunk in response.transform(utf8.decoder)) {
      final lines = chunk.split('\n');
      String? eventType;
      String? eventData;

      for (final line in lines) {
        if (line.startsWith('event: ')) {
          eventType = line.substring(7).trim();
        } else if (line.startsWith('data: ')) {
          eventData = line.substring(6);
        } else if (line.isEmpty && eventType != null && eventData != null) {
          // Process complete SSE event
          if (eventType == 'content_block_start') {
            try {
              final json = jsonDecode(eventData) as Map<String, dynamic>;
              final block = json['content_block'] as Map<String, dynamic>?;
              if (block?['type'] == 'tool_use') {
                currentToolId = block!['id'] as String? ?? '';
                currentToolName = block['name'] as String? ?? '';
                toolInputJson = '';
              }
            } catch (_) {}
          } else if (eventType == 'content_block_delta') {
            try {
              final json = jsonDecode(eventData) as Map<String, dynamic>;
              final delta = json['delta'] as Map<String, dynamic>?;
              if (delta?['type'] == 'text_delta') {
                final text = delta!['text'] as String? ?? '';
                fullText += text;
                yield ChatTextDelta(text);
              } else if (delta?['type'] == 'input_json_delta') {
                toolInputJson += delta!['partial_json'] as String? ?? '';
              }
            } catch (_) {}
          } else if (eventType == 'content_block_stop') {
            if (currentToolName.isNotEmpty) {
              Map<String, dynamic> input = {};
              try {
                input = jsonDecode(toolInputJson) as Map<String, dynamic>;
              } catch (_) {}
              yield ChatToolUse(
                id: currentToolId,
                name: currentToolName,
                input: input,
              );
              currentToolId = '';
              currentToolName = '';
              toolInputJson = '';
            }
          } else if (eventType == 'error') {
            final parsed = parseSseEvent(eventType, eventData);
            if (parsed != null) yield parsed;
          }

          eventType = null;
          eventData = null;
        }
      }
    }

    yield ChatDone(fullText);
  }

  void close() {
    _httpClient.close();
  }
}
