import 'package:aj_assistant/core/models/entry.dart';
import 'package:aj_assistant/core/models/module.dart';
import 'package:aj_assistant/core/theme/app_theme.dart';
import 'package:aj_assistant/features/blueprint/renderer/blueprint_node.dart';
import 'package:aj_assistant/features/blueprint/renderer/render_context.dart';
import 'package:aj_assistant/features/blueprint/renderer/widget_registry.dart';
import 'package:aj_assistant/features/schema/models/field_definition.dart';
import 'package:aj_assistant/features/schema/models/field_type.dart';
import 'package:aj_assistant/features/schema/models/module_schema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const testModule = Module(
    id: 'test',
    name: 'Test',
    schemas: {
      'default': ModuleSchema(
        fields: {
          'note': FieldDefinition(
            key: 'note',
            type: FieldType.text,
            label: 'Note',
          ),
          'amount': FieldDefinition(
            key: 'amount',
            type: FieldType.number,
            label: 'Amount',
          ),
        },
      ),
    },
  );

  const entries = [
    Entry(id: 'e1', data: {'note': 'Coffee', 'amount': 5}),
    Entry(id: 'e2', data: {'note': 'Lunch', 'amount': 15}),
    Entry(id: 'e3', data: {'note': 'Dinner', 'amount': 25}),
  ];

  setUpAll(() {
    WidgetRegistry.instance.registerDefaults();
  });

  Widget buildWidget({
    EntryListNode? node,
    List<Entry> testEntries = entries,
  }) {
    final listNode = node ??
        const EntryListNode(
          query: {'orderBy': 'amount', 'direction': 'desc'},
          itemLayout: EntryCardNode(
            titleTemplate: '{{note}}',
            trailingTemplate: '{{amount}}',
          ),
        );

    final ctx = RenderContext(
      module: testModule,
      entries: testEntries,
      allEntries: testEntries,
      onFormValueChanged: (_, _) {},
      onNavigateToScreen: (_, {Map<String, dynamic> params = const {}}) {},
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

  testWidgets('sorts entries by orderBy field', (tester) async {
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    // Desc order: Dinner (25), Lunch (15), Coffee (5)
    final allText = tester.widgetList(find.byType(Text))
        .map((w) => (w as Text).data)
        .where((t) => t != null && ['Coffee', 'Lunch', 'Dinner'].contains(t))
        .toList();

    expect(allText.first, 'Dinner');
    expect(allText.last, 'Coffee');
  });

  testWidgets('limits entries when limit is set', (tester) async {
    await tester.pumpWidget(buildWidget(
      node: const EntryListNode(
        query: {'limit': 2},
        itemLayout: EntryCardNode(titleTemplate: '{{note}}'),
      ),
    ));
    await tester.pumpAndSettle();

    // Should show only 2 of 3 entries
    final noteWidgets = tester.widgetList(find.byType(Text))
        .map((w) => (w as Text).data)
        .where((t) => t != null && ['Coffee', 'Lunch', 'Dinner'].contains(t))
        .toList();

    expect(noteWidgets.length, 2);
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

  testWidgets('shows "Show more" button when entries exceed display limit',
      (tester) async {
    // Create 5 entries but limit display to 2
    const manyEntries = [
      Entry(id: 'e1', data: {'note': 'A', 'amount': 1}),
      Entry(id: 'e2', data: {'note': 'B', 'amount': 2}),
      Entry(id: 'e3', data: {'note': 'C', 'amount': 3}),
      Entry(id: 'e4', data: {'note': 'D', 'amount': 4}),
      Entry(id: 'e5', data: {'note': 'E', 'amount': 5}),
    ];

    await tester.pumpWidget(buildWidget(
      node: const EntryListNode(
        query: {'limit': 2},
        itemLayout: EntryCardNode(titleTemplate: '{{note}}'),
      ),
      testEntries: manyEntries,
    ));
    await tester.pumpAndSettle();

    // Should show "Show more" button with remaining count
    expect(find.textContaining('Show more'), findsOneWidget);
    expect(find.textContaining('3 remaining'), findsOneWidget);
  });

  testWidgets('tapping "Show more" reveals more entries', (tester) async {
    const manyEntries = [
      Entry(id: 'e1', data: {'note': 'A', 'amount': 1}),
      Entry(id: 'e2', data: {'note': 'B', 'amount': 2}),
      Entry(id: 'e3', data: {'note': 'C', 'amount': 3}),
      Entry(id: 'e4', data: {'note': 'D', 'amount': 4}),
      Entry(id: 'e5', data: {'note': 'E', 'amount': 5}),
    ];

    await tester.pumpWidget(buildWidget(
      node: const EntryListNode(
        query: {'limit': 2},
        itemLayout: EntryCardNode(titleTemplate: '{{note}}'),
      ),
      testEntries: manyEntries,
    ));
    await tester.pumpAndSettle();

    // Initially: 2 visible, 3 hidden
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('C'), findsNothing);

    // Tap "Show more"
    await tester.tap(find.textContaining('Show more'));
    await tester.pumpAndSettle();

    // After tap: all 5 visible (2 + 20 > 5), no "Show more"
    expect(find.text('A'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
    expect(find.text('E'), findsOneWidget);
    expect(find.textContaining('Show more'), findsNothing);
  });
}
