import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aj_assistant/core/ai/claude_client.dart';
import 'package:aj_assistant/core/database/app_database.dart';
import 'package:aj_assistant/core/repositories/module_repository.dart';
import 'package:aj_assistant/features/chat/cubit/chat_cubit.dart';
import 'package:aj_assistant/features/chat/repositories/chat_repository.dart';

class MockClaudeClient extends Mock implements ClaudeClient {}

class MockAppDatabase extends Mock implements AppDatabase {}

class MockModuleRepository extends Mock implements ModuleRepository {}

class MockChatRepository extends Mock implements ChatRepository {}

void main() {
  late MockClaudeClient claude;
  late MockAppDatabase db;
  late MockModuleRepository moduleRepo;
  late MockChatRepository chatRepo;

  const userId = 'test_user';

  setUp(() {
    claude = MockClaudeClient();
    db = MockAppDatabase();
    moduleRepo = MockModuleRepository();
    chatRepo = MockChatRepository();
  });

  ChatCubit buildCubit() => ChatCubit(
        claude: claude,
        db: db,
        chatRepository: chatRepo,
        moduleRepository: moduleRepo,
        userId: userId,
        model: 'claude-sonnet-4-6',
      );

  test('initial state has no conversation and empty messages', () {
    final cubit = buildCubit();
    expect(cubit.state.conversationId, isNull);
    expect(cubit.state.messages, isEmpty);
    expect(cubit.state.isAiTyping, isFalse);
    cubit.close();
  });
}
