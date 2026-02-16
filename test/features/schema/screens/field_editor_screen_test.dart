import 'package:aj_assistant/features/schema/bloc/schema_bloc.dart';
import 'package:aj_assistant/features/schema/bloc/schema_event.dart';
import 'package:aj_assistant/features/schema/bloc/schema_state.dart';
import 'package:aj_assistant/features/schema/models/field_definition.dart';
import 'package:aj_assistant/features/schema/models/field_type.dart';
import 'package:aj_assistant/features/schema/models/module_schema.dart';
import 'package:aj_assistant/core/theme/app_theme.dart';
import 'package:aj_assistant/features/schema/screens/field_editor_screen.dart';
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
      fields: {
        'amount': FieldDefinition(
          key: 'amount',
          type: FieldType.currency,
          label: 'Amount',
          required: true,
          constraints: {'min': 0},
        ),
        'category': FieldDefinition(
          key: 'category',
          type: FieldType.enumType,
          label: 'Category',
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
      currentScreen: 'field_editor',
      screenParams: {'schemaKey': 'expense', 'fieldKey': 'amount'},
    );
    when(() => bloc.state).thenReturn(loadedState);
    whenListen(bloc, const Stream<SchemaState>.empty(),
        initialState: loadedState);
  });

  setUpAll(() {
    registerFallbackValue(const SchemaNavigateBack());
  });

  Widget buildSubject({Map<String, dynamic>? screenParams}) {
    if (screenParams != null) {
      final loadedState = SchemaLoaded(
        moduleId: 'mod1',
        schemas: testSchemas,
        currentScreen: 'field_editor',
        screenParams: screenParams,
      );
      when(() => bloc.state).thenReturn(loadedState);
      whenListen(bloc, const Stream<SchemaState>.empty(),
          initialState: loadedState);
    }
    return MaterialApp(
      theme: AppTheme.dark(),
      home: BlocProvider<SchemaBloc>.value(
        value: bloc,
        child: const FieldEditorScreen(),
      ),
    );
  }

  group('FieldEditorScreen', () {
    testWidgets('renders field properties — label, key, type, required',
        (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Label field
      expect(find.widgetWithText(TextFormField, 'Amount'), findsOneWidget);
      // Key field (read-only)
      expect(find.widgetWithText(TextFormField, 'amount'), findsOneWidget);
      // Required toggle should be on
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);
      final switchWidget = tester.widget<Switch>(switchFinder);
      expect(switchWidget.value, true);
    });

    testWidgets('type dropdown shows all FieldType values', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final dropdown = find.byType(DropdownButton<FieldType>);
      expect(dropdown, findsOneWidget);

      final dropdownWidget =
          tester.widget<DropdownButton<FieldType>>(dropdown);
      expect(dropdownWidget.value, FieldType.currency);
      expect(dropdownWidget.items!.length, FieldType.values.length);
    });

    testWidgets('toggle required switches value', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final switchFinder = find.byType(Switch);
      expect(tester.widget<Switch>(switchFinder).value, true);

      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(tester.widget<Switch>(switchFinder).value, false);
    });

    testWidgets('edit label updates text field', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final labelField = find.byKey(const Key('field_label_input'));
      await tester.enterText(labelField, 'Total Amount');
      await tester.pumpAndSettle();

      expect(
          find.widgetWithText(TextFormField, 'Total Amount'), findsOneWidget);
    });

    testWidgets('options editor not visible for non-enum types',
        (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('options_editor')), findsNothing);
    });

    testWidgets('options editor visible for enum types', (tester) async {
      await tester.pumpWidget(buildSubject(
        screenParams: {'schemaKey': 'expense', 'fieldKey': 'category'},
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('options_editor')), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Transport'), findsOneWidget);
      expect(find.text('Other'), findsOneWidget);
    });

    testWidgets('save button dispatches FieldUpdated', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final labelField = find.byKey(const Key('field_label_input'));
      await tester.enterText(labelField, 'Total Amount');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('save_field_button')));
      await tester.pumpAndSettle();

      verify(() => bloc.add(any(
            that: isA<FieldUpdated>()
                .having((e) => e.schemaKey, 'schemaKey', 'expense')
                .having((e) => e.fieldKey, 'fieldKey', 'amount')
                .having((e) => e.field.label, 'label', 'Total Amount'),
          ))).called(1);
    });

    testWidgets('constraints editor shows existing constraints',
        (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('constraints_editor')), findsOneWidget);
      expect(find.text('min: 0'), findsOneWidget);
    });

    testWidgets('add option shows bottom sheet', (tester) async {
      await tester.pumpWidget(buildSubject(
        screenParams: {'schemaKey': 'expense', 'fieldKey': 'category'},
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add option'));
      await tester.pumpAndSettle();

      expect(find.text('Add Option'), findsWidgets);
      expect(find.text('OPTION VALUE'), findsOneWidget);
    });

    testWidgets('add constraint shows bottom sheet', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add constraint'));
      await tester.pumpAndSettle();

      expect(find.text('Add Constraint'), findsWidgets);
      expect(find.text('KEY'), findsOneWidget);
      expect(find.text('VALUE'), findsOneWidget);
    });
  });
}
