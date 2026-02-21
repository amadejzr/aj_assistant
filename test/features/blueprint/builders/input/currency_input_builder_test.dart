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

  group('BlueprintParser — currency_input', () {
    test('creates CurrencyInputNode with defaults', () {
      final node = parser.parse({
        'type': 'currency_input',
        'fieldKey': 'amount',
      });

      expect(node, isA<CurrencyInputNode>());
      final input = node as CurrencyInputNode;
      expect(input.fieldKey, 'amount');
      expect(input.currencySymbol, '\$');
      expect(input.decimalPlaces, 2);
    });

    test('parses custom currencySymbol and decimalPlaces', () {
      final node = parser.parse({
        'type': 'currency_input',
        'fieldKey': 'price',
        'currencySymbol': '€',
        'decimalPlaces': 0,
      });

      final input = node as CurrencyInputNode;
      expect(input.currencySymbol, '€');
      expect(input.decimalPlaces, 0);
    });
  });

  group('currency_input builder', () {
    const testModule = Module(
      id: 'test',
      name: 'Test',
    );

    setUpAll(() {
      WidgetRegistry.instance.registerDefaults();
    });

    Widget buildWidget({
      CurrencyInputNode? node,
      Map<String, dynamic> formValues = const {},
      void Function(String, dynamic)? onChanged,
    }) {
      final inputNode = node ??
          const CurrencyInputNode(
            fieldKey: 'amount',
            properties: {'label': 'Amount'},
          );

      final ctx = RenderContext(
        module: testModule,
        formValues: formValues,
        onFormValueChanged: onChanged ?? (_, _) {},
        onNavigateToScreen: (_, {Map<String, dynamic> params = const {}}) {},
      );

      return MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: WidgetRegistry.instance.build(inputNode, ctx),
        ),
      );
    }

    testWidgets('renders with label from node properties', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('Amount'), findsOneWidget);
    });

    testWidgets('renders currency symbol prefix', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('\$ '), findsOneWidget);
    });

    testWidgets('renders custom currency symbol', (tester) async {
      await tester.pumpWidget(buildWidget(
        node: const CurrencyInputNode(
          fieldKey: 'amount',
          currencySymbol: '€',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('€ '), findsOneWidget);
    });

    testWidgets('calls onFormValueChanged when typing', (tester) async {
      String? changedKey;
      dynamic changedValue;

      await tester.pumpWidget(buildWidget(
        onChanged: (key, value) {
          changedKey = key;
          changedValue = value;
        },
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), '42.50');
      expect(changedKey, 'amount');
      expect(changedValue, 42.50);
    });

    testWidgets('shows existing value from formValues', (tester) async {
      await tester.pumpWidget(buildWidget(
        formValues: {'amount': 99.99},
      ));
      await tester.pumpAndSettle();

      expect(find.text('99.99'), findsOneWidget);
    });

    testWidgets('registry resolves currency_input', (tester) async {
      const node = CurrencyInputNode(fieldKey: 'amount');
      final ctx = RenderContext(
        module: testModule,
        onFormValueChanged: (_, _) {},
        onNavigateToScreen: (_, {Map<String, dynamic> params = const {}}) {},
      );

      final widget = WidgetRegistry.instance.build(node, ctx);
      expect(widget, isNot(isA<SizedBox>()));
    });
  });
}
