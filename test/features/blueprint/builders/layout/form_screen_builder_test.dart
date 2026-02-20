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

  setUpAll(() {
    WidgetRegistry.instance.registerDefaults();
  });

  Widget buildWidget({
    FormScreenNode? node,
    Map<String, dynamic> formValues = const {},
    Map<String, dynamic> screenParams = const {},
    void Function(String, dynamic)? onChanged,
    VoidCallback? onSubmit,
  }) {
    final formNode = node ??
        const FormScreenNode(
          title: 'Add Expense',
          submitLabel: 'Save',
          children: [
            TextInputNode(fieldKey: 'note'),
            NumberInputNode(fieldKey: 'amount'),
          ],
        );

    final ctx = RenderContext(
      module: testModule,
      formValues: formValues,
      screenParams: screenParams,
      onFormValueChanged: onChanged ?? (_, _) {},
      onNavigateToScreen: (_, {Map<String, dynamic> params = const {}}) {},
      onFormSubmit: onSubmit,
    );

    return MaterialApp(
      theme: AppTheme.dark(),
      home: WidgetRegistry.instance.build(formNode, ctx),
    );
  }

  testWidgets('renders title in app bar', (tester) async {
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    expect(find.text('Add Expense'), findsOneWidget);
  });

  testWidgets('renders submit button with label', (tester) async {
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets('renders form children', (tester) async {
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    // text_input and number_input should render their labels
    expect(find.text('Note'), findsOneWidget);
    expect(find.text('Amount'), findsOneWidget);
  });

  testWidgets('uses editLabel when _entryId is present', (tester) async {
    await tester.pumpWidget(buildWidget(
      node: const FormScreenNode(
        title: 'Edit',
        submitLabel: 'Create',
        editLabel: 'Update',
        children: [],
      ),
      screenParams: {'_entryId': 'entry123'},
    ));
    await tester.pumpAndSettle();

    expect(find.text('Update'), findsOneWidget);
    expect(find.text('Create'), findsNothing);
  });

  testWidgets('uses submitLabel when no _entryId', (tester) async {
    await tester.pumpWidget(buildWidget(
      node: const FormScreenNode(
        title: 'New',
        submitLabel: 'Create',
        editLabel: 'Update',
        children: [],
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Create'), findsOneWidget);
    expect(find.text('Update'), findsNothing);
  });

  testWidgets('registry resolves form_screen', (tester) async {
    const node = FormScreenNode(title: 'Test', children: []);
    final ctx = RenderContext(
      module: testModule,
      onFormValueChanged: (_, _) {},
      onNavigateToScreen: (_, {Map<String, dynamic> params = const {}}) {},
    );

    final widget = WidgetRegistry.instance.build(node, ctx);
    expect(widget, isNot(isA<SizedBox>()));
  });
}
