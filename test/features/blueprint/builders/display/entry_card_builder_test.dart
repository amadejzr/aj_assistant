import 'package:aj_assistant/core/models/module.dart';
import 'package:aj_assistant/core/theme/app_theme.dart';
import 'package:aj_assistant/features/blueprint/renderer/blueprint_node.dart';
import 'package:aj_assistant/features/blueprint/renderer/render_context.dart';
import 'package:aj_assistant/features/blueprint/renderer/widget_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const testModule = Module(
    id: 'expenses',
    name: 'Finances',
  );

  const testEntryData = {
    'id': 'exp1',
    'note': 'Lunch',
    'category': 'cat1',
    'amount': 15.5,
  };

  setUpAll(() {
    WidgetRegistry.instance.registerDefaults();
  });

  Widget buildWidget({
    EntryCardNode? node,
    Map<String, dynamic> formValues = testEntryData,
    Map<String, dynamic> screenParams = const {},
    void Function(String, {Map<String, dynamic> params})? onNavigate,
  }) {
    final cardNode = node ??
        const EntryCardNode(
          titleTemplate: '{{note}}',
          subtitleTemplate: '{{category}}',
          trailingTemplate: '{{amount}}',
        );

    final ctx = RenderContext(
      module: testModule,
      formValues: formValues,
      screenParams: screenParams,
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
    // No subtitle rendered when subtitleTemplate is null
    expect(find.text('cat1'), findsNothing);
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
      formValues: testEntryData,
      onFormValueChanged: (_, _) {},
      onNavigateToScreen: (_, {Map<String, dynamic> params = const {}}) {},
    );

    final widget = WidgetRegistry.instance.build(node, ctx);
    expect(widget, isNot(isA<SizedBox>()));
  });
}
