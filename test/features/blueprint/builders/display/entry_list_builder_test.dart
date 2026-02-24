import 'package:bowerlab/core/models/module.dart';
import 'package:bowerlab/core/theme/app_theme.dart';
import 'package:bowerlab/features/blueprint/renderer/blueprint_node.dart';
import 'package:bowerlab/features/blueprint/renderer/render_context.dart';
import 'package:bowerlab/features/blueprint/renderer/widget_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const testModule = Module(
    id: 'test',
    name: 'Test',
  );

  const entries = [
    {'id': 'e1', 'note': 'Coffee', 'amount': 5},
    {'id': 'e2', 'note': 'Lunch', 'amount': 15},
    {'id': 'e3', 'note': 'Dinner', 'amount': 25},
  ];

  setUpAll(() {
    WidgetRegistry.instance.registerDefaults();
  });

  String? lastNavigatedScreen;

  Widget buildWidget({
    EntryListNode? node,
    List<Map<String, dynamic>> testEntries = entries,
  }) {
    lastNavigatedScreen = null;

    final listNode = node ??
        EntryListNode(
          query: const {'orderBy': 'amount', 'direction': 'desc'},
          itemLayout: const EntryCardNode(
            titleTemplate: '{{note}}',
            trailingTemplate: '{{amount}}',
          ),
          properties: const {'source': 'test_source'},
        );

    final ctx = RenderContext(
      module: testModule,
      queryResults: {'test_source': testEntries},
      onFormValueChanged: (_, _) {},
      onNavigateToScreen: (screen, {Map<String, dynamic> params = const {}}) {
        lastNavigatedScreen = screen;
      },
    );

    return MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: WidgetRegistry.instance.build(listNode, ctx),
        ),
      ),
    );
  }

  testWidgets('renders entry cards for each entry', (tester) async {
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    expect(find.text('Coffee'), findsOneWidget);
    expect(find.text('Lunch'), findsOneWidget);
    expect(find.text('Dinner'), findsOneWidget);
  });

  testWidgets('shows empty state when no entries', (tester) async {
    await tester.pumpWidget(buildWidget(testEntries: const []));
    await tester.pumpAndSettle();

    expect(find.text('No entries yet'), findsOneWidget);
  });

  testWidgets('registry resolves entry_list', (tester) async {
    const node = EntryListNode();
    final ctx = RenderContext(
      module: testModule,
      onFormValueChanged: (_, _) {},
      onNavigateToScreen: (_, {Map<String, dynamic> params = const {}}) {},
    );

    final widget = WidgetRegistry.instance.build(node, ctx);
    expect(widget, isNot(isA<SizedBox>()));
  });

  testWidgets('summary mode — shows title and "View all" when entries exceed limit',
      (tester) async {
    const manyEntries = [
      {'id': 'e1', 'note': 'A', 'amount': 1},
      {'id': 'e2', 'note': 'B', 'amount': 2},
      {'id': 'e3', 'note': 'C', 'amount': 3},
      {'id': 'e4', 'note': 'D', 'amount': 4},
      {'id': 'e5', 'note': 'E', 'amount': 5},
    ];

    await tester.pumpWidget(buildWidget(
      node: const EntryListNode(
        title: 'Recent Expenses',
        query: {'limit': 2},
        viewAllScreen: 'all_expenses',
        itemLayout: EntryCardNode(titleTemplate: '{{note}}'),
        properties: {'source': 'test_source'},
      ),
      testEntries: manyEntries,
    ));
    await tester.pumpAndSettle();

    expect(find.text('Recent Expenses'), findsOneWidget);
    expect(find.text('View all'), findsOneWidget);
  });

  testWidgets('summary mode — tapping "View all" navigates to viewAllScreen',
      (tester) async {
    const manyEntries = [
      {'id': 'e1', 'note': 'A', 'amount': 1},
      {'id': 'e2', 'note': 'B', 'amount': 2},
      {'id': 'e3', 'note': 'C', 'amount': 3},
      {'id': 'e4', 'note': 'D', 'amount': 4},
      {'id': 'e5', 'note': 'E', 'amount': 5},
    ];

    await tester.pumpWidget(buildWidget(
      node: const EntryListNode(
        title: 'Recent Expenses',
        query: {'limit': 2},
        viewAllScreen: 'all_expenses',
        itemLayout: EntryCardNode(titleTemplate: '{{note}}'),
        properties: {'source': 'test_source'},
      ),
      testEntries: manyEntries,
    ));
    await tester.pumpAndSettle();

    // Only 2 items visible
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('C'), findsNothing);

    // Tap the title/view all area
    await tester.tap(find.text('View all'));
    await tester.pumpAndSettle();

    expect(lastNavigatedScreen, 'all_expenses');
  });

  testWidgets('summary mode — no "View all" when all entries fit in limit',
      (tester) async {
    await tester.pumpWidget(buildWidget(
      node: const EntryListNode(
        title: 'Recent Expenses',
        query: {'limit': 10},
        viewAllScreen: 'all_expenses',
        itemLayout: EntryCardNode(titleTemplate: '{{note}}'),
        properties: {'source': 'test_source'},
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Recent Expenses'), findsOneWidget);
    expect(find.text('View all'), findsNothing);
  });
}
