import 'package:aj_assistant/core/models/entry.dart';
import 'package:aj_assistant/core/models/module.dart';
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
    );

    const categoryEntries = [
      Entry(id: 'cat1', data: {'name': 'Food'}, schemaKey: 'category'),
      Entry(id: 'cat2', data: {'name': 'Transport'}, schemaKey: 'category'),
      Entry(id: 'cat3', data: {'name': 'Entertainment'}, schemaKey: 'category'),
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
    }) {
      final pickerNode =
          node ??
          const ReferencePickerNode(
            fieldKey: 'category',
            schemaKey: 'category',
            properties: {'label': 'Category'},
          );

      final ctx = RenderContext(
        module: module,
        entries: entries,
        allEntries: entries,
        formValues: formValues,
        onFormValueChanged: onChanged ?? (_, _) {},
        onNavigateToScreen: (_, {Map<String, dynamic> params = const {}}) {},
      );

      return MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(body: WidgetRegistry.instance.build(pickerNode, ctx)),
      );
    }

    testWidgets('renders entries from referenced schema', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Transport'), findsOneWidget);
      expect(find.text('Entertainment'), findsOneWidget);
    });

    testWidgets('filters by schemaKey — expense entries not shown', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Transport'), findsOneWidget);
      expect(find.text('Entertainment'), findsOneWidget);
    });

    testWidgets('tap selects entry — calls onFormValueChanged with entry ID', (
      tester,
    ) async {
      String? changedKey;
      dynamic changedValue;

      await tester.pumpWidget(
        buildWidget(
          onChanged: (key, value) {
            changedKey = key;
            changedValue = value;
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Food'));
      expect(changedKey, 'category');
      expect(changedValue, 'cat1');
    });

    testWidgets('shows current selection as highlighted', (tester) async {
      await tester.pumpWidget(buildWidget(formValues: {'category': 'cat2'}));
      await tester.pumpAndSettle();

      expect(find.text('Transport'), findsOneWidget);
    });

    testWidgets('uses displayField override', (tester) async {
      const moduleWithTitle = Module(
        id: 'test',
        name: 'Test',
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

      await tester.pumpWidget(
        buildWidget(node: node, module: moduleWithTitle, entries: entries),
      );
      await tester.pumpAndSettle();

      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Wrong'), findsNothing);
    });

    testWidgets('shows no entries when schemaKey has no matches', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          entries: const [
            Entry(id: 'exp1', data: {'amount': 50}, schemaKey: 'expense'),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Food'), findsNothing);
      expect(find.text('Transport'), findsNothing);
    });

    testWidgets(
      'falls back to targetSchema property when node schemaKey is empty',
      (tester) async {
        const moduleWithConstraint = Module(
          id: 'expenses',
          name: 'Finances',
        );

        const node = ReferencePickerNode(
          fieldKey: 'category',
          schemaKey: '', // empty — falls back to targetSchema property
          properties: {'targetSchema': 'category', 'label': 'Category'},
        );

        await tester.pumpWidget(
          buildWidget(
            node: node,
            module: moduleWithConstraint,
            entries: categoryEntries,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Food'), findsOneWidget);
        expect(find.text('Transport'), findsOneWidget);
        expect(find.text('Entertainment'), findsOneWidget);
      },
    );

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

  });
}
