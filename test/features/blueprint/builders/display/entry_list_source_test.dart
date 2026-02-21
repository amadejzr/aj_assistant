import 'package:aj_assistant/core/models/module.dart';
import 'package:aj_assistant/core/theme/app_theme.dart';
import 'package:aj_assistant/features/blueprint/renderer/blueprint_node.dart';
import 'package:aj_assistant/features/blueprint/renderer/render_context.dart';
import 'package:aj_assistant/features/blueprint/renderer/widget_registry.dart';
import 'package:aj_assistant/features/modules/models/field_definition.dart';
import 'package:aj_assistant/features/modules/models/field_type.dart';
import 'package:aj_assistant/features/modules/models/module_schema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const testModule = Module(
    id: 'test',
    name: 'Test',
    schemas: {
      'default': ModuleSchema(
        fields: {
          'description': FieldDefinition(
            key: 'description',
            type: FieldType.text,
            label: 'Description',
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

  setUpAll(() {
    WidgetRegistry.instance.registerDefaults();
  });

  Widget buildWidget({
    required EntryListNode node,
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
        body: SingleChildScrollView(
          child: WidgetRegistry.instance.build(node, ctx),
        ),
      ),
    );
  }

  group('entry_list with source', () {
    testWidgets('reads from queryResults', (tester) async {
      await tester.pumpWidget(buildWidget(
        node: const EntryListNode(
          itemLayout: EntryCardNode(
            titleTemplate: '{{description}}',
            trailingTemplate: '{{amount}}',
          ),
          properties: {'source': 'expenses'},
        ),
        queryResults: {
          'expenses': [
            {'description': 'Coffee', 'amount': 5.0},
            {'description': 'Lunch', 'amount': 15.0},
          ],
        },
      ));
      await tester.pumpAndSettle();

      expect(find.text('Coffee'), findsOneWidget);
      expect(find.text('Lunch'), findsOneWidget);
    });

    testWidgets('empty queryResults shows empty state', (tester) async {
      await tester.pumpWidget(buildWidget(
        node: const EntryListNode(
          itemLayout: EntryCardNode(
            titleTemplate: '{{description}}',
          ),
          properties: {'source': 'expenses'},
        ),
        queryResults: {
          'expenses': [],
        },
      ));
      await tester.pumpAndSettle();

      expect(find.text('No entries yet'), findsOneWidget);
    });

    testWidgets('missing source key shows empty state', (tester) async {
      await tester.pumpWidget(buildWidget(
        node: const EntryListNode(
          itemLayout: EntryCardNode(
            titleTemplate: '{{description}}',
          ),
          properties: {'source': 'nonexistent'},
        ),
        queryResults: {},
      ));
      await tester.pumpAndSettle();

      expect(find.text('No entries yet'), findsOneWidget);
    });

    testWidgets('without source uses ctx.entries (backward compat)',
        (tester) async {
      final ctx = RenderContext(
        module: testModule,
        entries: const [],
        onFormValueChanged: (_, _) {},
        onNavigateToScreen: (_, {Map<String, dynamic> params = const {}}) {},
      );

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: WidgetRegistry.instance.build(
              const EntryListNode(
                itemLayout: EntryCardNode(
                  titleTemplate: '{{description}}',
                ),
              ),
              ctx,
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Empty entries → empty state
      expect(find.text('No entries yet'), findsOneWidget);
    });
  });
}
