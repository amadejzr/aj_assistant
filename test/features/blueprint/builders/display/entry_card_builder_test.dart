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
          'note': FieldDefinition(
            key: 'note',
            type: FieldType.text,
            label: 'Note',
          ),
          'category': FieldDefinition(
            key: 'category',
            type: FieldType.reference,
            label: 'Category',
            constraints: {'schemaKey': 'category'},
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

  const allEntries = [
    Entry(id: 'cat1', data: {'name': 'Food'}, schemaKey: 'category'),
    Entry(id: 'cat2', data: {'name': 'Transport'}, schemaKey: 'category'),
    Entry(
      id: 'exp1',
      data: {'note': 'Lunch', 'category': 'cat1', 'amount': 15.5},
      schemaKey: 'expense',
    ),
  ];

  setUpAll(() {
    WidgetRegistry.instance.registerDefaults();
  });

  Widget buildWidget({
    EntryCardNode? node,
    Entry? entry,
    void Function(String, {Map<String, dynamic> params})? onNavigate,
  }) {
    final cardNode = node ??
        const EntryCardNode(
          titleTemplate: '{{note}}',
          subtitleTemplate: '{{category}}',
          trailingTemplate: '{{amount}}',
        );

    final testEntry = entry ?? allEntries.last;

    final ctx = RenderContext(
      module: testModule,
      entries: [testEntry],
      allEntries: allEntries,
      formValues: testEntry.data,
      onFormValueChanged: (_, _) {},
      onNavigateToScreen: onNavigate ??
          (_, {Map<String, dynamic> params = const {}}) {},
    );

    return MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(
        body: WidgetRegistry.instance.build(cardNode, ctx),
      ),
    );
  }

  testWidgets('renders title from template', (tester) async {
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    expect(find.text('Lunch'), findsOneWidget);
  });

  testWidgets('resolves reference fields to display values', (tester) async {
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    // {{category}} should resolve cat1 -> "Food" not show "cat1"
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('cat1'), findsNothing);
  });

  testWidgets('renders trailing value', (tester) async {
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    expect(find.text('15.5'), findsOneWidget);
  });

  testWidgets('hides subtitle when empty', (tester) async {
    await tester.pumpWidget(buildWidget(
      node: const EntryCardNode(titleTemplate: '{{note}}'),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Lunch'), findsOneWidget);
    // No subtitle rendered
    expect(find.text('Food'), findsNothing);
  });

  testWidgets('onTap navigates to specified screen', (tester) async {
    String? navigatedScreen;
    Map<String, dynamic>? navigatedParams;

    await tester.pumpWidget(buildWidget(
      node: const EntryCardNode(
        titleTemplate: '{{note}}',
        onTap: {'screen': 'edit_entry', 'forwardFields': ['note']},
      ),
      onNavigate: (screen, {Map<String, dynamic> params = const {}}) {
        navigatedScreen = screen;
        navigatedParams = params;
      },
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lunch'));
    await tester.pumpAndSettle();

    expect(navigatedScreen, 'edit_entry');
    expect(navigatedParams?['note'], 'Lunch');
    expect(navigatedParams?['_entryId'], 'exp1');
  });

  testWidgets('registry resolves entry_card', (tester) async {
    const node = EntryCardNode(titleTemplate: '{{note}}');
    final ctx = RenderContext(
      module: testModule,
      entries: [allEntries[2]],
      allEntries: allEntries,
      formValues: allEntries[2].data,
      onFormValueChanged: (_, _) {},
      onNavigateToScreen: (_, {Map<String, dynamic> params = const {}}) {},
    );

    final widget = WidgetRegistry.instance.build(node, ctx);
    expect(widget, isNot(isA<SizedBox>()));
  });
}
