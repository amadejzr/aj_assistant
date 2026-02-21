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
    );

    setUpAll(() {
      WidgetRegistry.instance.registerDefaults();
    });

    Widget buildWidget({
      StatCardNode? node,
      Map<String, dynamic> resolvedExpressions = const {},
      Map<String, List<Map<String, dynamic>>> queryResults = const {},
    }) {
      final cardNode = node ??
          const StatCardNode(label: 'Count', stat: 'count');

      final ctx = RenderContext(
        module: testModule,
        resolvedExpressions: resolvedExpressions,
        queryResults: queryResults,
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
      await tester.pumpWidget(buildWidget(
        queryResults: {
          'count_source': [
            {'count': 3},
          ],
        },
        node: const StatCardNode(
          label: 'Count',
          stat: 'count',
          properties: {'source': 'count_source', 'valueKey': 'count'},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('COUNT'), findsOneWidget); // label is uppercased
    });

    testWidgets('computes stat from SQL source', (tester) async {
      await tester.pumpWidget(buildWidget(
        node: const StatCardNode(
          label: 'Count',
          stat: 'count',
          properties: {'source': 'count_source', 'valueKey': 'count'},
        ),
        queryResults: {
          'count_source': [
            {'count': 3},
          ],
        },
      ));
      await tester.pumpAndSettle();

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('computes expression-based stat from resolvedExpressions',
        (tester) async {
      await tester.pumpWidget(buildWidget(
        node: const StatCardNode(
          label: 'Total',
          stat: 'count',
          expression: 'sum(amount)',
        ),
        resolvedExpressions: {'sum(amount)': 100},
      ));
      await tester.pumpAndSettle();

      expect(find.text('100'), findsOneWidget);
    });

    testWidgets('shows -- when no source and no resolvedExpressions',
        (tester) async {
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
          properties: {'accent': true, 'source': 'count_source', 'valueKey': 'count'},
        ),
        queryResults: {
          'count_source': [
            {'count': 3},
          ],
        },
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

    testWidgets('uses resolvedExpressions from context', (tester) async {
      final ctx = RenderContext(
        module: testModule,
        resolvedExpressions: const {'sum(amount)': 100},
        onFormValueChanged: (_, _) {},
        onNavigateToScreen: (_, {Map<String, dynamic> params = const {}}) {},
      );

      const node = StatCardNode(
        label: 'Cached Total',
        stat: 'count',
        expression: 'sum(amount)',
      );

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: WidgetRegistry.instance.build(node, ctx),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('100'), findsOneWidget);
    });
  });
}
