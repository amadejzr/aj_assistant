import 'package:aj_assistant/features/modules/models/field_definition.dart';
import 'package:aj_assistant/features/modules/models/field_type.dart';
import 'package:aj_assistant/features/modules/models/module_schema.dart';
import 'package:aj_assistant/core/theme/app_theme.dart';
import 'package:aj_assistant/features/blueprint/widgets/reference_entry_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const testSchema = ModuleSchema(
    label: 'Category',
    fields: {
      'name': FieldDefinition(
        key: 'name',
        type: FieldType.text,
        label: 'Category Name',
      ),
      'budget': FieldDefinition(
        key: 'budget',
        type: FieldType.number,
        label: 'Monthly Budget',
      ),
      'active': FieldDefinition(
        key: 'active',
        type: FieldType.boolean,
        label: 'Active',
      ),
      'parent': FieldDefinition(
        key: 'parent',
        type: FieldType.reference,
        label: 'Parent Category',
      ),
    },
  );

  Widget buildSheet({
    Map<String, dynamic>? initialData,
    void Function(Map<String, dynamic>)? onSubmit,
  }) {
    return MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(
        body: ReferenceEntrySheet(
          schema: testSchema,
          schemaLabel: 'Category',
          initialData: initialData,
          onSubmit: onSubmit ?? (_) {},
        ),
      ),
    );
  }

  group('ReferenceEntrySheet', () {
    testWidgets('renders form fields for schema fields', (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.pumpAndSettle();

      // Should show labels for non-reference fields
      expect(find.text('Category Name'), findsOneWidget);
      expect(find.text('Monthly Budget'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('shows "Create Category" title in create mode',
        (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.pumpAndSettle();

      expect(find.text('Create Category'), findsOneWidget);
    });

    testWidgets('shows "Edit Category" title in edit mode', (tester) async {
      await tester.pumpWidget(buildSheet(
        initialData: {'name': 'Food'},
      ));
      await tester.pumpAndSettle();

      expect(find.text('Edit Category'), findsOneWidget);
    });

    testWidgets('pre-fills fields in edit mode', (tester) async {
      await tester.pumpWidget(buildSheet(
        initialData: {'name': 'Food', 'budget': 500},
      ));
      await tester.pumpAndSettle();

      // TextFormField should have initial value
      final nameField = find.widgetWithText(TextFormField, 'Food');
      expect(nameField, findsOneWidget);

      final budgetField = find.widgetWithText(TextFormField, '500');
      expect(budgetField, findsOneWidget);
    });

    testWidgets('skips reference-type fields', (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.pumpAndSettle();

      // "Parent Category" is a reference field — should not render
      expect(find.text('Parent Category'), findsNothing);
    });

    testWidgets('shows Create button in create mode', (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ElevatedButton, 'Create'), findsOneWidget);
    });

    testWidgets('shows Save button in edit mode', (tester) async {
      await tester.pumpWidget(buildSheet(
        initialData: {'name': 'Food'},
      ));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ElevatedButton, 'Save'), findsOneWidget);
    });
  });

  group('ReferenceEntrySheet.show — modal', () {
    testWidgets('returns form data on submit', (tester) async {
      Map<String, dynamic>? result;

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await ReferenceEntrySheet.show(
                  context: context,
                  schema: const ModuleSchema(
                    label: 'Category',
                    fields: {
                      'name': FieldDefinition(
                        key: 'name',
                        type: FieldType.text,
                        label: 'Name',
                      ),
                    },
                  ),
                  schemaLabel: 'Category',
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Open the sheet
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Verify the sheet is shown
      expect(find.text('Create Category'), findsOneWidget);

      // Type into the name field
      await tester.enterText(find.byType(TextFormField), 'Food');
      await tester.pumpAndSettle();

      // Tap Create
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!['name'], 'Food');
    });
  });
}
