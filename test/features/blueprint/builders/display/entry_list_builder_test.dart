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
}
