import 'package:aj_assistant/core/models/module.dart';
import 'package:aj_assistant/core/theme/app_theme.dart';
import 'package:aj_assistant/features/blueprint/renderer/blueprint_node.dart';
import 'package:aj_assistant/features/blueprint/renderer/render_context.dart';
import 'package:aj_assistant/features/blueprint/renderer/widget_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const testModule = Module(id: 'test', name: 'Test');

  setUpAll(() {
    WidgetRegistry.instance.registerDefaults();
  });

  Widget buildWidget({
    required StatCardNode node,
    Map<String, List<Map<String, dynamic>>> queryResults = const {},
  }) {
    final ctx = RenderContext(
      module: testModule,
      onFormValueChanged: (_, _) {},
      onNavigateToScreen: (_, {Map<String, dynamic> params = const {}}) {},
      queryResults: queryResults,
    );

    return MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(
        body: WidgetRegistry.instance.build(node, ctx),
      ),
    );
  }

  group('stat_card with source', () {
    testWidgets('reads value from queryResults via source + valueKey',
        (tester) async {
      await tester.pumpWidget(buildWidget(
        node: const StatCardNode(
          label: 'Total',
          stat: 'count',
          properties: {'source': 'summary', 'valueKey': 'total_amount'},
        ),
        queryResults: {
          'summary': [
            {'total_amount': 42.0},
          ],
        },
      ));
      await tester.pumpAndSettle();

      expect(find.text('TOTAL'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('formats decimal values', (tester) async {
      await tester.pumpWidget(buildWidget(
        node: const StatCardNode(
          label: 'Average',
          stat: 'count',
          properties: {'source': 'stats', 'valueKey': 'avg'},
        ),
        queryResults: {
          'stats': [
            {'avg': 3.7},
          ],
        },
      ));
      await tester.pumpAndSettle();

      expect(find.text('3.7'), findsOneWidget);
    });

    testWidgets('shows -- for null/missing value', (tester) async {
      await tester.pumpWidget(buildWidget(
        node: const StatCardNode(
          label: 'Empty',
          stat: 'count',
          properties: {'source': 'stats', 'valueKey': 'missing'},
        ),
        queryResults: {
          'stats': [
            {'other': 10},
          ],
        },
      ));
      await tester.pumpAndSettle();

      expect(find.text('--'), findsOneWidget);
    });

    testWidgets('shows -- for empty queryResults', (tester) async {
      await tester.pumpWidget(buildWidget(
        node: const StatCardNode(
          label: 'None',
          stat: 'count',
          properties: {'source': 'stats', 'valueKey': 'total'},
        ),
        queryResults: {},
      ));
      await tester.pumpAndSettle();

      expect(find.text('--'), findsOneWidget);
    });

    testWidgets('without source or expression shows --', (tester) async {
      await tester.pumpWidget(buildWidget(
        node: const StatCardNode(
          label: 'Count',
          stat: 'count',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('COUNT'), findsOneWidget);
      expect(find.text('--'), findsOneWidget);
    });
  });
}
