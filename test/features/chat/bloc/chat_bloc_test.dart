import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aj_assistant/core/ai/claude_client.dart';
import 'package:aj_assistant/core/database/app_database.dart';
import 'package:aj_assistant/core/repositories/module_repository.dart';
import 'package:aj_assistant/features/chat/bloc/chat_bloc.dart';
import 'package:aj_assistant/features/chat/bloc/chat_state.dart';

class MockClaudeClient extends Mock implements ClaudeClient {}

class MockAppDatabase extends Mock implements AppDatabase {}

class MockModuleRepository extends Mock implements ModuleRepository {}

void main() {
  late MockClaudeClient claude;
  late MockAppDatabase db;
  late MockModuleRepository moduleRepo;

  const userId = 'test_user';

  setUp(() {
    claude = MockClaudeClient();
    db = MockAppDatabase();
    moduleRepo = MockModuleRepository();
  });

  ChatBloc buildBloc() => ChatBloc(
        claude: claude,
        db: db,
        moduleRepository: moduleRepo,
        userId: userId,
      );

  test('initial state is ChatInitial', () {
    final bloc = buildBloc();
    expect(bloc.state, isA<ChatInitial>());
    bloc.close();
  });
}
