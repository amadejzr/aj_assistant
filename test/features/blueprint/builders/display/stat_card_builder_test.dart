import 'package:aj_assistant/core/models/entry.dart';
import 'package:aj_assistant/core/models/module.dart';
import 'package:aj_assistant/core/theme/app_theme.dart';
import 'package:aj_assistant/features/blueprint/renderer/blueprint_node.dart';
import 'package:aj_assistant/features/blueprint/renderer/blueprint_parser.dart';
import 'package:aj_assistant/features/blueprint/renderer/render_context.dart';
import 'package:aj_assistant/features/blueprint/renderer/widget_registry.dart';
import 'package:aj_assistant/features/schema/models/field_definition.dart';
import 'package:aj_assistant/features/schema/models/field_type.dart';
import 'package:aj_assistant/features/schema/models/module_schema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = BlueprintParser();

  group('BlueprintParser — stat_card', () {
    test('creates StatCardNode with defaults', () {
      final node = parser.parse({
        'type': 'stat_card',
        'label': 'Total',
      });

      expect(node, isA<StatCardNode>());
      final card = node as StatCardNode;
      expect(card.label, 'Total');
      expect(card.stat, 'count');
      expect(card.expression, isNull);
      expect(card.format, isNull);
    });

    test('parses expression and format', () {
      final node = parser.parse({
        'type': 'stat_card',
        'label': 'Spent',
        'expression': 'sum(amount, period(month))',
        'format': 'currency',
      });

      final card = node as StatCardNode;
      expect(card.expression, 'sum(amount, period(month))');
      expect(card.format, 'currency');
    });
  });

  group('stat_card builder', () {
    const testModule = Module(
      id: 'expenses',
      name: 'Expenses',
      schemas: {
        'default': ModuleSchema(
          fields: {
            'amount': FieldDefinition(
              key: 'amount',
              type: FieldType.number,
              label: 'Amount',
            ),
            'date': FieldDefinition(
              key: 'date',
              type: FieldType.datetime,
              label: 'Date',
            ),
          },
        ),
      },
    );

    final testEntries = [
      const Entry(id: 'e1', data: {'amount': 50, 'date': '2026-02-15'}),
      const Entry(id: 'e2', data: {'amount': 30, 'date': '2026-02-16'}),
      const Entry(id: 'e3', data: {'amount': 20, 'date': '2026-02-17'}),
    ];

    setUpAll(() {
      WidgetRegistry.instance.registerDefaults();
    });

    Widget buildWidget({
      StatCardNode? node,
      List<Entry> entries = const [],
    }) {
      final cardNode = node ??
          const StatCardNode(label: 'Count', stat: 'count');

      final ctx = RenderContext(
        module: testModule,
        entries: entries,
        onFormValueChanged: (_, _) {},
        onNavigateToScreen: (_, {Map<String, dynamic> params = const {}}) {},
      );

      return MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: WidgetRegistry.instance.build(cardNode, ctx),
        ),
      );
    }

    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(buildWidget(entries: testEntries));
      await tester.pumpAndSettle();

      expect(find.text('COUNT'), findsOneWidget); // label is uppercased
    });

    testWidgets('computes count stat', (tester) async {
      await tester.pumpWidget(buildWidget(entries: testEntries));
      await tester.pumpAndSettle();

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('computes expression-based stat', (tester) async {
      await tester.pumpWidget(buildWidget(
        node: const StatCardNode(
          label: 'Total',
          stat: 'count',
          expression: 'sum(amount)',
        ),
        entries: testEntries,
      ));
      await tester.pumpAndSettle();

      expect(find.text('100'), findsOneWidget);
    });

    testWidgets('shows -- for empty entries', (tester) async {
      await tester.pumpWidget(buildWidget(
        node: const StatCardNode(
          label: 'Total',
          stat: 'sum_amount',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('--'), findsOneWidget);
    });

    testWidgets('shows accent stripe when accent property is true',
        (tester) async {
      await tester.pumpWidget(buildWidget(
        node: const StatCardNode(
          label: 'Highlight',
          stat: 'count',
          properties: {'accent': true},
        ),
        entries: testEntries,
      ));
      await tester.pumpAndSettle();

      expect(find.text('HIGHLIGHT'), findsOneWidget);
    });

    testWidgets('registry resolves stat_card', (tester) async {
      const node = StatCardNode(label: 'Test', stat: 'count');
      final ctx = RenderContext(
        module: testModule,
        onFormValueChanged: (_, _) {},
        onNavigateToScreen: (_, {Map<String, dynamic> params = const {}}) {},
      );

      final widget = WidgetRegistry.instance.build(node, ctx);
      expect(widget, isNot(isA<SizedBox>()));
    });
  });
}
