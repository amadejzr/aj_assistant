import 'package:aj_assistant/features/schema/bloc/schema_bloc.dart';
import 'package:aj_assistant/features/schema/bloc/schema_event.dart';
import 'package:aj_assistant/features/schema/bloc/schema_state.dart';
import 'package:aj_assistant/features/schema/models/field_definition.dart';
import 'package:aj_assistant/features/schema/models/field_type.dart';
import 'package:aj_assistant/features/schema/models/module_schema.dart';
import 'package:aj_assistant/core/theme/app_theme.dart';
import 'package:aj_assistant/features/schema/screens/schema_editor_screen.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSchemaBloc extends MockBloc<SchemaEvent, SchemaState>
    implements SchemaBloc {}

void main() {
  late MockSchemaBloc bloc;

  const testSchemas = {
    'expense': ModuleSchema(
      label: 'Expense',
      icon: 'wallet',
      fields: {
        'amount': FieldDefinition(
          key: 'amount',
          type: FieldType.currency,
          label: 'Amount',
          required: true,
        ),
        'note': FieldDefinition(
          key: 'note',
          type: FieldType.text,
          label: 'Note',
        ),
        'category': FieldDefinition(
          key: 'category',
          type: FieldType.enumType,
          label: 'Category',
          required: true,
          options: ['Food', 'Transport', 'Other'],
        ),
      },
    ),
  };

  setUp(() {
    bloc = MockSchemaBloc();
    final loadedState = const SchemaLoaded(
      moduleId: 'mod1',
      schemas: testSchemas,
      currentScreen: 'editor',
      screenParams: {'schemaKey': 'expense'},
    );
    when(() => bloc.state).thenReturn(loadedState);
    whenListen(bloc, const Stream<SchemaState>.empty(),
        initialState: loadedState);
  });

  setUpAll(() {
    registerFallbackValue(const SchemaNavigateBack());
  });

  Widget buildSubject() {
    return MaterialApp(
      theme: AppTheme.dark(),
      home: BlocProvider<SchemaBloc>.value(
        value: bloc,
        child: const SchemaEditorScreen(),
      ),
    );
  }

  group('SchemaEditorScreen', () {
    testWidgets('renders schema label as editable text field', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final labelField = find.byKey(const Key('schema_label_input'));
      expect(labelField, findsOneWidget);
      expect(
        find.widgetWithText(TextField, 'Expense'),
        findsOneWidget,
      );
    });

    testWidgets('renders all fields', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Amount'), findsOneWidget);
      expect(find.text('Note'), findsOneWidget);
      expect(find.text('Category'), findsOneWidget);
    });

    testWidgets('shows field type badge', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('currency'), findsOneWidget);
      expect(find.text('text'), findsOneWidget);
      expect(find.text('enumType'), findsOneWidget);
    });

    testWidgets('shows required indicator', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final requiredIndicators = find.text('*');
      // amount and category are required
      expect(requiredIndicators, findsNWidgets(2));
    });

    testWidgets('edit label triggers SchemaUpdated', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final labelField = find.byKey(const Key('schema_label_input'));
      await tester.enterText(labelField, 'Updated Expense');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      verify(() => bloc.add(any(
            that: isA<SchemaUpdated>().having(
              (e) => e.schema.label,
              'updated label',
              'Updated Expense',
            ),
          ))).called(1);
    });

    testWidgets('tap field navigates to field editor', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Amount'));
      await tester.pumpAndSettle();

      verify(() => bloc.add(
            const SchemaScreenChanged(
              'field_editor',
              params: {'schemaKey': 'expense', 'fieldKey': 'amount'},
            ),
          )).called(1);
    });

    testWidgets('add field button shows bottom sheet', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('add_field_button')));
      await tester.pumpAndSettle();

      // Bottom sheet should show title and type chips
      expect(find.text('Add Field'), findsWidgets);
      expect(find.byKey(const Key('type_chip_text')), findsOneWidget);
    });

    testWidgets('add field sheet creates field with key and label',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('add_field_button')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('field_key_input')),
        'tags',
      );
      await tester.enterText(
        find.byKey(const Key('field_label_input')),
        'Tags',
      );

      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('submit_field_button')));
      await tester.pumpAndSettle();

      verify(() => bloc.add(any(
            that: isA<FieldAdded>()
                .having((e) => e.schemaKey, 'schemaKey', 'expense')
                .having((e) => e.fieldKey, 'fieldKey', 'tags')
                .having((e) => e.field.label, 'label', 'Tags')
                .having((e) => e.field.type, 'type', FieldType.text),
          ))).called(1);
    });

    testWidgets('delete field via long-press', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.longPress(find.text('Note'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Field'), findsOneWidget);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      verify(() => bloc.add(
            const FieldDeleted('expense', 'note'),
          )).called(1);
    });
  });
}
