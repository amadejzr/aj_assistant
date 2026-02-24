import 'package:bowerlab/core/models/module.dart';
import 'package:bowerlab/core/theme/app_theme.dart';
import 'package:bowerlab/features/blueprint/renderer/blueprint_node.dart';
import 'package:bowerlab/features/blueprint/renderer/blueprint_parser.dart';
import 'package:bowerlab/features/blueprint/renderer/render_context.dart';
import 'package:bowerlab/features/blueprint/renderer/widget_registry.dart';
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

  // --- Widget tests ---

  group('reference_picker builder', () {
    const testModule = Module(
      id: 'expenses',
      name: 'Finances',
    );

    const categoryRows = [
      {'id': 'cat1', 'name': 'Food'},
      {'id': 'cat2', 'name': 'Transport'},
      {'id': 'cat3', 'name': 'Entertainment'},
    ];

    setUpAll(() {
      WidgetRegistry.instance.registerDefaults();
    });

    Widget buildWidget({
      ReferencePickerNode? node,
      Module module = testModule,
      List<Map<String, dynamic>> sourceRows = categoryRows,
      Map<String, dynamic> formValues = const {},
      void Function(String, dynamic)? onChanged,
    }) {
      final pickerNode =
          node ??
          const ReferencePickerNode(
            fieldKey: 'category',
            schemaKey: 'category',
            properties: {'label': 'Category', 'source': 'category_source'},
          );

      final sourceKey =
          pickerNode.properties['source'] as String? ?? 'category_source';

      final ctx = RenderContext(
        module: module,
        formValues: formValues,
        queryResults: {sourceKey: sourceRows},
        onFormValueChanged: onChanged ?? (_, _) {},
        onNavigateToScreen: (_, {Map<String, dynamic> params = const {}}) {},
      );

      return MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(body: WidgetRegistry.instance.build(pickerNode, ctx)),
      );
    }

    testWidgets('renders entries from queryResults source', (tester) async {
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

      const rows = [
        {'id': 'i1', 'title': 'Alpha', 'name': 'Wrong'},
      ];

      const node = ReferencePickerNode(
        fieldKey: 'ref',
        schemaKey: 'item',
        displayField: 'title',
        properties: {'source': 'item_source'},
      );

      await tester.pumpWidget(
        buildWidget(node: node, module: moduleWithTitle, sourceRows: rows),
      );
      await tester.pumpAndSettle();

      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Wrong'), findsNothing);
    });

    testWidgets('shows no entries when source has no data', (tester) async {
      await tester.pumpWidget(
        buildWidget(sourceRows: const []),
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
          properties: {
            'targetSchema': 'category',
            'label': 'Category',
            'source': 'category_source',
          },
        );

        await tester.pumpWidget(
          buildWidget(
            node: node,
            module: moduleWithConstraint,
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
        properties: {'source': 'category_source'},
      );

      final ctx = RenderContext(
        module: testModule,
        queryResults: const {
          'category_source': categoryRows,
        },
        onFormValueChanged: (_, _) {},
        onNavigateToScreen: (_, {Map<String, dynamic> params = const {}}) {},
      );

      final widget = WidgetRegistry.instance.build(node, ctx);
      expect(widget, isNot(isA<SizedBox>()));
    });

  });
}
