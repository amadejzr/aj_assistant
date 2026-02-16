import 'package:aj_assistant/core/models/field_definition.dart';
import 'package:aj_assistant/core/models/field_type.dart';
import 'package:aj_assistant/core/models/module.dart';
import 'package:aj_assistant/core/models/module_schema.dart';
import 'package:aj_assistant/core/theme/app_theme.dart';
import 'package:aj_assistant/features/module_viewer/bloc/module_viewer_bloc.dart';
import 'package:aj_assistant/features/module_viewer/bloc/module_viewer_event.dart';
import 'package:aj_assistant/features/module_viewer/bloc/module_viewer_state.dart';
import 'package:aj_assistant/features/module_viewer/screens/module_settings_screen.dart';
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
        icon: 'wallet',
        fields: {
          'amount': FieldDefinition(
            key: 'amount',
            type: FieldType.currency,
            label: 'Amount',
          ),
          'note': FieldDefinition(
            key: 'note',
            type: FieldType.text,
            label: 'Note',
          ),
          'date': FieldDefinition(
            key: 'date',
            type: FieldType.datetime,
            label: 'Date',
          ),
        },
      ),
      'category': ModuleSchema(
        label: 'Category',
        fields: {
          'name': FieldDefinition(
            key: 'name',
            type: FieldType.text,
            label: 'Name',
          ),
        },
      ),
    },
  );

  setUp(() {
    bloc = MockModuleViewerBloc();
    when(() => bloc.state).thenReturn(
      ModuleViewerLoaded(module: testModule),
    );
  });

  Widget buildSubject() {
    return MaterialApp(
      theme: AppTheme.dark(),
      home: BlocProvider<ModuleViewerBloc>.value(
        value: bloc,
        child: const ModuleSettingsScreen(),
      ),
    );
  }

  group('ModuleSettingsScreen', () {
    testWidgets('renders all schemas', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Expense'), findsOneWidget);
      expect(find.text('Category'), findsOneWidget);
    });

    testWidgets('shows schema label, falls back to key', (tester) async {
      when(() => bloc.state).thenReturn(
        ModuleViewerLoaded(
          module: testModule.copyWith(schemas: {
            'expense': const ModuleSchema(label: 'Expense'),
            'unlabeled': const ModuleSchema(label: ''),
          }),
        ),
      );

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Expense'), findsOneWidget);
      expect(find.text('unlabeled'), findsOneWidget);
    });

    testWidgets('shows field count per schema', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('3 fields'), findsOneWidget);
      expect(find.text('1 field'), findsOneWidget);
    });

    testWidgets('tap schema card navigates to schema editor', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Expense'));
      await tester.pumpAndSettle();

      verify(() => bloc.add(
            const ModuleViewerScreenChanged(
              '_schema_editor',
              params: {'schemaKey': 'expense'},
            ),
          )).called(1);
    });

    testWidgets('add schema button shows bottom sheet and creates schema',
        (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('add_schema_button')));
      await tester.pumpAndSettle();

      // Bottom sheet should appear with title
      expect(find.text('Create Schema'), findsOneWidget);

      // Enter schema key
      await tester.enterText(
        find.byKey(const Key('schema_key_field')),
        'budget',
      );
      // Enter schema label
      await tester.enterText(
        find.byKey(const Key('schema_label_field')),
        'Budget',
      );
      await tester.tap(find.byKey(const Key('create_schema_button')));
      await tester.pumpAndSettle();

      verify(() => bloc.add(
            const ModuleViewerSchemaAdded(
              'budget',
              ModuleSchema(label: 'Budget'),
            ),
          )).called(1);
    });

    testWidgets('add schema with inline fields', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('add_schema_button')));
      await tester.pumpAndSettle();

      // Enter schema info
      await tester.enterText(
        find.byKey(const Key('schema_key_field')),
        'task',
      );
      await tester.enterText(
        find.byKey(const Key('schema_label_field')),
        'Task',
      );

      // Add a field via the inline builder
      await tester.tap(find.byKey(const Key('add_field_to_schema_button')));
      await tester.pumpAndSettle();

      // Fill in field details
      await tester.enterText(
        find.byKey(const Key('field_draft_key_0')),
        'title',
      );
      await tester.enterText(
        find.byKey(const Key('field_draft_label_0')),
        'Title',
      );

      // Submit
      await tester.tap(find.byKey(const Key('create_schema_button')));
      await tester.pumpAndSettle();

      verify(() => bloc.add(any(
            that: isA<ModuleViewerSchemaAdded>()
                .having((e) => e.schemaKey, 'schemaKey', 'task')
                .having((e) => e.schema.label, 'label', 'Task')
                .having(
                    (e) => e.schema.fields.containsKey('title'), 'has title field', true),
          ))).called(1);
    });

    testWidgets('delete schema via long-press', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.longPress(find.text('Category'));
      await tester.pumpAndSettle();

      // Confirm dialog
      expect(find.text('Delete Schema'), findsOneWidget);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      verify(() => bloc.add(const ModuleViewerSchemaDeleted('category')))
          .called(1);
    });
  });
}
