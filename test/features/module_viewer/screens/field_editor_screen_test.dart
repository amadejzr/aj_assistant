import 'package:aj_assistant/core/models/field_definition.dart';
import 'package:aj_assistant/core/models/field_type.dart';
import 'package:aj_assistant/core/models/module.dart';
import 'package:aj_assistant/core/models/module_schema.dart';
import 'package:aj_assistant/core/theme/app_theme.dart';
import 'package:aj_assistant/features/module_viewer/bloc/module_viewer_bloc.dart';
import 'package:aj_assistant/features/module_viewer/bloc/module_viewer_event.dart';
import 'package:aj_assistant/features/module_viewer/bloc/module_viewer_state.dart';
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
    },
  );

  setUp(() {
    bloc = MockModuleViewerBloc();
    final loadedState = ModuleViewerLoaded(
      module: testModule,
      currentScreenId: '_field_editor',
      screenParams: const {'schemaKey': 'expense', 'fieldKey': 'amount'},
    );
    when(() => bloc.state).thenReturn(loadedState);
    whenListen(bloc, const Stream<ModuleViewerState>.empty(),
        initialState: loadedState);
  });

  setUpAll(() {
    registerFallbackValue(const ModuleViewerNavigateBack());
  });

  Widget buildSubject({Map<String, dynamic>? screenParams}) {
    if (screenParams != null) {
      final loadedState = ModuleViewerLoaded(
        module: testModule,
        currentScreenId: '_field_editor',
        screenParams: screenParams,
      );
      when(() => bloc.state).thenReturn(loadedState);
      whenListen(bloc, const Stream<ModuleViewerState>.empty(),
          initialState: loadedState);
    }
    return MaterialApp(
      theme: AppTheme.dark(),
      home: BlocProvider<ModuleViewerBloc>.value(
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

      // Find the dropdown
      final dropdown = find.byType(DropdownButton<FieldType>);
      expect(dropdown, findsOneWidget);

      // Current value should be shown
      final dropdownWidget =
          tester.widget<DropdownButton<FieldType>>(dropdown);
      expect(dropdownWidget.value, FieldType.currency);

      // All field types should be in the items list
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

      expect(find.widgetWithText(TextFormField, 'Total Amount'), findsOneWidget);
    });

    testWidgets('options editor not visible for non-enum types',
        (tester) async {
      // Amount is currency — no options editor
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('options_editor')), findsNothing);
    });

    testWidgets('options editor visible for enum types', (tester) async {
      // Category is enumType — has options editor
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

      // Change the label
      final labelField = find.byKey(const Key('field_label_input'));
      await tester.enterText(labelField, 'Total Amount');
      await tester.pumpAndSettle();

      // Tap save
      await tester.tap(find.byKey(const Key('save_field_button')));
      await tester.pumpAndSettle();

      verify(() => bloc.add(any(
            that: isA<ModuleViewerFieldUpdated>()
                .having((e) => e.schemaKey, 'schemaKey', 'expense')
                .having((e) => e.fieldKey, 'fieldKey', 'amount')
                .having((e) => e.field.label, 'label', 'Total Amount'),
          ))).called(1);
    });

    testWidgets('constraints editor shows existing constraints',
        (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // The amount field has constraint min: 0
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

      // Bottom sheet should appear with styled title
      expect(find.text('Add Option'), findsWidgets);
      expect(find.text('OPTION VALUE'), findsOneWidget);
    });

    testWidgets('add constraint shows bottom sheet', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add constraint'));
      await tester.pumpAndSettle();

      // Bottom sheet should appear with styled title
      expect(find.text('Add Constraint'), findsWidgets);
      expect(find.text('KEY'), findsOneWidget);
      expect(find.text('VALUE'), findsOneWidget);
    });
  });
}
