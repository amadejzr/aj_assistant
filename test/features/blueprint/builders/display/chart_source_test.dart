import 'package:bowerlab/core/models/module.dart';
import 'package:bowerlab/core/theme/app_theme.dart';
import 'package:bowerlab/features/blueprint/renderer/blueprint_node.dart';
import 'package:bowerlab/features/blueprint/renderer/render_context.dart';
import 'package:bowerlab/features/blueprint/renderer/widget_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const testModule = Module(id: 'test', name: 'Test');

  setUpAll(() {
    WidgetRegistry.instance.registerDefaults();
  });

  Widget buildWidget({
    required ChartNode node,
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

  group('chart with source', () {
    testWidgets('reads grouped data from queryResults', (tester) async {
      await tester.pumpWidget(buildWidget(
        node: const ChartNode(
          chartType: 'bar',
          properties: {
            'source': 'by_category',
            'groupKey': 'category',
            'valueField': 'total',
          },
        ),
        queryResults: {
          'by_category': [
            {'category': 'Food', 'total': 250},
            {'category': 'Transport', 'total': 80},
          ],
        },
      ));
      await tester.pumpAndSettle();

      // Bar chart renders — check for labels
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Transpo…'), findsOneWidget); // truncated to 7 chars + ellipsis
    });

    testWidgets('empty source data renders empty chart', (tester) async {
      await tester.pumpWidget(buildWidget(
        node: const ChartNode(
          chartType: 'donut',
          properties: {'source': 'by_category'},
        ),
        queryResults: {
          'by_category': [],
        },
      ));
      await tester.pumpAndSettle();

      expect(find.text('No data to display'), findsOneWidget);
    });

    testWidgets('without source uses expression path (backward compat)',
        (tester) async {
      await tester.pumpWidget(buildWidget(
        node: const ChartNode(
          chartType: 'donut',
          groupBy: 'category',
        ),
      ));
      await tester.pumpAndSettle();

      // No entries → empty chart
      expect(find.text('No data to display'), findsOneWidget);
    });
  });
}
