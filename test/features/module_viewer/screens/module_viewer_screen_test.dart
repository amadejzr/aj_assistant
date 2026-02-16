import 'package:aj_assistant/core/models/field_definition.dart';
import 'package:aj_assistant/core/models/field_type.dart';
import 'package:aj_assistant/core/models/module.dart';
import 'package:aj_assistant/core/models/module_schema.dart';
import 'package:aj_assistant/core/theme/app_theme.dart';
import 'package:aj_assistant/features/module_viewer/bloc/module_viewer_bloc.dart';
import 'package:aj_assistant/features/module_viewer/bloc/module_viewer_event.dart';
import 'package:aj_assistant/features/module_viewer/bloc/module_viewer_state.dart';
import 'package:aj_assistant/features/module_viewer/screens/module_settings_screen.dart';
import 'package:aj_assistant/features/module_viewer/screens/schema_editor_screen.dart';
import 'package:aj_assistant/features/module_viewer/screens/field_editor_screen.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockModuleViewerBloc
    extends MockBloc<ModuleViewerEvent, ModuleViewerState>
    implements ModuleViewerBloc {}

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
    testWidgets('_settings route renders ModuleSettingsScreen', (tester) async {
      await tester.pumpWidget(buildBody(
        ModuleViewerLoaded(
          module: testModule,
          currentScreenId: '_settings',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(ModuleSettingsScreen), findsOneWidget);
    });

    testWidgets('_schema_editor route renders SchemaEditorScreen',
        (tester) async {
      await tester.pumpWidget(buildBody(
        ModuleViewerLoaded(
          module: testModule,
          currentScreenId: '_schema_editor',
          screenParams: const {'schemaKey': 'expense'},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(SchemaEditorScreen), findsOneWidget);
    });

    testWidgets('_field_editor route renders FieldEditorScreen',
        (tester) async {
      await tester.pumpWidget(buildBody(
        ModuleViewerLoaded(
          module: testModule,
          currentScreenId: '_field_editor',
          screenParams: const {
            'schemaKey': 'expense',
            'fieldKey': 'amount',
          },
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(FieldEditorScreen), findsOneWidget);
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
      expect(find.byType(ModuleSettingsScreen), findsNothing);
    });
  });
}

Widget _buildSettingsScreen(ModuleViewerLoaded state) {
  return switch (state.currentScreenId) {
    '_settings' => const ModuleSettingsScreen(),
    '_schema_editor' => const SchemaEditorScreen(),
    '_field_editor' => const FieldEditorScreen(),
    _ => const Scaffold(body: Text('Unknown settings screen')),
  };
}
