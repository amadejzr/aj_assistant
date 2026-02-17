import 'package:aj_assistant/core/models/entry.dart';
import 'package:aj_assistant/core/models/module.dart';
import 'package:aj_assistant/features/schema/models/field_definition.dart';
import 'package:aj_assistant/features/schema/models/field_type.dart';
import 'package:aj_assistant/features/schema/models/module_schema.dart';
import 'package:aj_assistant/core/theme/app_theme.dart';
import 'package:aj_assistant/features/blueprint/renderer/blueprint_node.dart';
import 'package:aj_assistant/features/blueprint/renderer/blueprint_parser.dart';
import 'package:aj_assistant/features/blueprint/renderer/render_context.dart';
import 'package:aj_assistant/features/blueprint/renderer/widget_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = BlueprintParser();

  group('BlueprintParser — reference_picker', () {
    test('creates ReferencePickerNode with fieldKey and schemaKey', () {
      final node = parser.parse({
        'type': 'reference_picker',
        'fieldKey': 'category',
        'schemaKey': 'category',
      });

      expect(node, isA<ReferencePickerNode>());
      final picker = node as ReferencePickerNode;
      expect(picker.fieldKey, 'category');
      expect(picker.schemaKey, 'category');
      expect(picker.displayField, 'name'); // default
    });

    test('handles displayField override', () {
      final node = parser.parse({
        'type': 'reference_picker',
        'fieldKey': 'account',
        'schemaKey': 'account',
        'displayField': 'title',
      });

      final picker = node as ReferencePickerNode;
      expect(picker.displayField, 'title');
    });

    test('unknown type still returns UnknownNode', () {
      final node = parser.parse({'type': 'totally_unknown_widget'});
      expect(node, isA<UnknownNode>());
    });
  });

  // ─── Widget tests ───

  group('reference_picker builder', () {
    const testModule = Module(
      id: 'expenses',
      name: 'Finances',
      schemas: {
        'category': ModuleSchema(
          label: 'Category',
          fields: {
            'name': FieldDefinition(
              key: 'name',
              type: FieldType.text,
              label: 'Category Name',
            ),
          },
        ),
        'expense': ModuleSchema(
          label: 'Expense',
          fields: {
            'category': FieldDefinition(
              key: 'category',
              type: FieldType.reference,
              label: 'Category',
            ),
          },
        ),
      },
    );

    const categoryEntries = [
      Entry(id: 'cat1', data: {'name': 'Food'}, schemaKey: 'category'),
      Entry(id: 'cat2', data: {'name': 'Transport'}, schemaKey: 'category'),
      Entry(
          id: 'cat3',
          data: {'name': 'Entertainment'},
          schemaKey: 'category'),
    ];

    const expenseEntries = [
      Entry(id: 'exp1', data: {'amount': 50}, schemaKey: 'expense'),
    ];

    const allEntries = [...categoryEntries, ...expenseEntries];

    setUpAll(() {
      WidgetRegistry.instance.registerDefaults();
    });

    Widget buildWidget({
      ReferencePickerNode? node,
      Module module = testModule,
      List<Entry> entries = allEntries,
      Map<String, dynamic> formValues = const {},
      void Function(String, dynamic)? onChanged,
      Future<String?> Function(String, Map<String, dynamic>)? onCreateEntry,
      Future<void> Function(String, String, Map<String, dynamic>)?
          onUpdateEntry,
    }) {
      final pickerNode = node ??
          const ReferencePickerNode(
            fieldKey: 'category',
            schemaKey: 'category',
          );

      final ctx = RenderContext(
        module: module,
        entries: entries,
        allEntries: entries,
        formValues: formValues,
        onFormValueChanged: onChanged ?? (_, _) {},
        onNavigateToScreen: (_, {Map<String, dynamic> params = const {}}) {},
        onCreateEntry: onCreateEntry,
        onUpdateEntry: onUpdateEntry,
      );

      return MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: WidgetRegistry.instance.build(pickerNode, ctx),
        ),
      );
    }

    testWidgets('renders entries from referenced schema', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Transport'), findsOneWidget);
      expect(find.text('Entertainment'), findsOneWidget);
    });

    testWidgets('filters by schemaKey — expense entries not shown',
        (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Transport'), findsOneWidget);
      expect(find.text('Entertainment'), findsOneWidget);
    });

    testWidgets('tap selects entry — calls onFormValueChanged with entry ID',
        (tester) async {
      String? changedKey;
      dynamic changedValue;

      await tester.pumpWidget(buildWidget(
        onChanged: (key, value) {
          changedKey = key;
          changedValue = value;
        },
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Food'));
      expect(changedKey, 'category');
      expect(changedValue, 'cat1');
    });

    testWidgets('shows current selection as highlighted', (tester) async {
      await tester.pumpWidget(buildWidget(
        formValues: {'category': 'cat2'},
      ));
      await tester.pumpAndSettle();

      expect(find.text('Transport'), findsOneWidget);
    });

    testWidgets('uses displayField override', (tester) async {
      const moduleWithTitle = Module(
        id: 'test',
        name: 'Test',
        schemas: {
          'item': ModuleSchema(
            label: 'Item',
            fields: {
              'title': FieldDefinition(
                key: 'title',
                type: FieldType.text,
                label: 'Title',
              ),
            },
          ),
        },
      );

      const entries = [
        Entry(
          id: 'i1',
          data: {'title': 'Alpha', 'name': 'Wrong'},
          schemaKey: 'item',
        ),
      ];

      const node = ReferencePickerNode(
        fieldKey: 'ref',
        schemaKey: 'item',
        displayField: 'title',
      );

      await tester.pumpWidget(buildWidget(
        node: node,
        module: moduleWithTitle,
        entries: entries,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Wrong'), findsNothing);
    });

    testWidgets('empty state shows "+" add chip', (tester) async {
      await tester.pumpWidget(buildWidget(
        entries: const [
          Entry(id: 'exp1', data: {'amount': 50}, schemaKey: 'expense'),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Food'), findsNothing);
      expect(find.text('Transport'), findsNothing);
      // "+" chip still present
      expect(find.text('New'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('falls back to field constraint schemaKey when node omits it',
        (tester) async {
      const moduleWithConstraint = Module(
        id: 'expenses',
        name: 'Finances',
        schemas: {
          'category': ModuleSchema(
            label: 'Category',
            fields: {
              'name': FieldDefinition(
                key: 'name',
                type: FieldType.text,
                label: 'Category Name',
              ),
            },
          ),
          'expense': ModuleSchema(
            label: 'Expense',
            fields: {
              'category': FieldDefinition(
                key: 'category',
                type: FieldType.reference,
                label: 'Category',
                constraints: {'schemaKey': 'category'},
              ),
            },
          ),
        },
      );

      const node = ReferencePickerNode(
        fieldKey: 'category',
        schemaKey: '', // empty — should fall back
      );

      await tester.pumpWidget(buildWidget(
        node: node,
        module: moduleWithConstraint,
        entries: categoryEntries,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Transport'), findsOneWidget);
      expect(find.text('Entertainment'), findsOneWidget);
    });

    testWidgets('registry resolves reference_picker', (tester) async {
      const node = ReferencePickerNode(
        fieldKey: 'category',
        schemaKey: 'category',
      );

      final ctx = RenderContext(
        module: testModule,
        entries: categoryEntries,
        allEntries: categoryEntries,
        onFormValueChanged: (_, _) {},
        onNavigateToScreen: (_, {Map<String, dynamic> params = const {}}) {},
      );

      final widget = WidgetRegistry.instance.build(node, ctx);
      expect(widget, isNot(isA<SizedBox>()));
    });

    // ─── New tests for inline create/edit ───

    testWidgets('renders "+" add chip after entries', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('New'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('"+" chip opens bottom sheet on tap', (tester) async {
      await tester.pumpWidget(buildWidget(
        onCreateEntry: (schemaKey, data) async => 'new-id',
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('New'));
      await tester.pumpAndSettle();

      // Bottom sheet should show "Create Category"
      expect(find.text('Create Category'), findsOneWidget);
    });

    testWidgets('long-press chip opens edit sheet', (tester) async {
      await tester.pumpWidget(buildWidget(
        onUpdateEntry: (entryId, schemaKey, data) async {},
      ));
      await tester.pumpAndSettle();

      await tester.longPress(find.text('Food'));
      await tester.pumpAndSettle();

      // Bottom sheet should show "Edit Category"
      expect(find.text('Edit Category'), findsOneWidget);
      // Should pre-fill the name field
      expect(find.widgetWithText(TextFormField, 'Food'), findsOneWidget);
    });

    testWidgets('empty state shows "+" chip for inline create',
        (tester) async {
      await tester.pumpWidget(buildWidget(
        entries: const [], // no entries at all
      ));
      await tester.pumpAndSettle();

      // Even with no entries, "+" chip should be there
      expect(find.text('New'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });
  });
}
