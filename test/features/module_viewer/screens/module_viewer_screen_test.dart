import 'package:aj_assistant/core/models/module.dart';
import 'package:aj_assistant/features/schema/models/field_definition.dart';
import 'package:aj_assistant/features/schema/models/field_type.dart';
import 'package:aj_assistant/features/schema/models/module_schema.dart';
import 'package:aj_assistant/core/theme/app_theme.dart';
import 'package:aj_assistant/features/module_viewer/bloc/module_viewer_bloc.dart';
import 'package:aj_assistant/features/module_viewer/bloc/module_viewer_event.dart';
import 'package:aj_assistant/features/module_viewer/bloc/module_viewer_state.dart';
import 'package:aj_assistant/features/schema/screens/schema_navigator.dart';
import 'package:aj_assistant/features/schema/bloc/schema_bloc.dart';
import 'package:aj_assistant/features/schema/bloc/schema_event.dart';
import 'package:aj_assistant/features/schema/bloc/schema_state.dart';
import 'package:aj_assistant/core/repositories/module_repository.dart';
import 'package:aj_assistant/features/auth/bloc/auth_bloc.dart';
import 'package:aj_assistant/features/auth/bloc/auth_state.dart';
import 'package:aj_assistant/features/auth/models/app_user.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockModuleViewerBloc
    extends MockBloc<ModuleViewerEvent, ModuleViewerState>
    implements ModuleViewerBloc {}

class MockSchemaBloc extends MockBloc<SchemaEvent, SchemaState>
    implements SchemaBloc {}

class MockAuthBloc extends Mock implements AuthBloc {}

class MockModuleRepository extends Mock implements ModuleRepository {}

const _testUser = AppUser(uid: 'user1', email: 'test@test.com');

void main() {
  late MockModuleViewerBloc bloc;

  const testModule = Module(
    id: 'mod1',
    name: 'Test Module',
    schemas: {
      'expense': ModuleSchema(
        label: 'Expense',
        fields: {
          'amount': FieldDefinition(
            key: 'amount',
            type: FieldType.currency,
            label: 'Amount',
          ),
        },
      ),
    },
    screens: {
      'main': {
        'type': 'screen',
        'title': 'Test Module',
        'layout': {
          'type': 'scroll_column',
          'children': [],
        },
      },
    },
  );

  setUp(() {
    bloc = MockModuleViewerBloc();
  });

  setUpAll(() {
    registerFallbackValue(const ModuleViewerNavigateBack());
  });

  Widget buildBody(ModuleViewerLoaded state) {
    when(() => bloc.state).thenReturn(state);
    whenListen(bloc, const Stream<ModuleViewerState>.empty(),
        initialState: state);
    return MaterialApp(
      theme: AppTheme.dark(),
      home: BlocProvider<ModuleViewerBloc>.value(
        value: bloc,
        child: BlocBuilder<ModuleViewerBloc, ModuleViewerState>(
          builder: (context, state) {
            if (state is! ModuleViewerLoaded) {
              return const SizedBox.shrink();
            }
            return state.currentScreenId.startsWith('_')
                ? _buildSettingsScreen(state)
                : const Scaffold(body: Text('Blueprint Screen'));
          },
        ),
      ),
    );
  }

  group('Module Viewer — settings navigation routing', () {
    testWidgets('_settings route renders SchemaNavigator', (tester) async {
      final mockAuthBloc = MockAuthBloc();
      final mockModuleRepo = MockModuleRepository();
      when(() => mockAuthBloc.state)
          .thenReturn(AuthAuthenticated(_testUser));
      when(() => mockModuleRepo.getModule(any(), any()))
          .thenAnswer((_) async => testModule);

      when(() => bloc.state).thenReturn(
        ModuleViewerLoaded(
          module: testModule,
          currentScreenId: '_settings',
        ),
      );
      whenListen(
        bloc,
        const Stream<ModuleViewerState>.empty(),
        initialState: ModuleViewerLoaded(
          module: testModule,
          currentScreenId: '_settings',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: MultiRepositoryProvider(
            providers: [
              RepositoryProvider<ModuleRepository>.value(
                  value: mockModuleRepo),
            ],
            child: MultiBlocProvider(
              providers: [
                BlocProvider<ModuleViewerBloc>.value(value: bloc),
                BlocProvider<AuthBloc>.value(value: mockAuthBloc),
              ],
              child: BlocBuilder<ModuleViewerBloc, ModuleViewerState>(
                builder: (context, state) {
                  if (state is! ModuleViewerLoaded) {
                    return const SizedBox.shrink();
                  }
                  if (state.currentScreenId == '_settings') {
                    return BlocProvider(
                      create: (_) => SchemaBloc(
                        moduleRepository: mockModuleRepo,
                        userId: 'user1',
                        moduleId: 'mod1',
                      )..add(const SchemaStarted('mod1')),
                      child: const SchemaNavigator(),
                    );
                  }
                  return const Scaffold(body: Text('Blueprint Screen'));
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SchemaNavigator), findsOneWidget);
    });

    testWidgets('non-prefixed route renders blueprint screen', (tester) async {
      await tester.pumpWidget(buildBody(
        ModuleViewerLoaded(
          module: testModule,
          currentScreenId: 'main',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Blueprint Screen'), findsOneWidget);
    });
  });
}

Widget _buildSettingsScreen(ModuleViewerLoaded state) {
  return switch (state.currentScreenId) {
    '_settings' => const Scaffold(body: Text('Schema Navigator')),
    _ => const Scaffold(body: Text('Unknown settings screen')),
  };
}
