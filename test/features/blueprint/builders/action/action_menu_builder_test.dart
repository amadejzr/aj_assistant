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

  group('BlueprintParser — action_menu', () {
    test('creates ActionMenuNode with defaults', () {
      final node = parser.parse({
        'type': 'action_menu',
      });

      expect(node, isA<ActionMenuNode>());
      final menu = node as ActionMenuNode;
      expect(menu.icon, 'dots-three');
      expect(menu.items, isEmpty);
    });

    test('parses items list', () {
      final node = parser.parse({
        'type': 'action_menu',
        'icon': 'gear',
        'items': [
          {'label': 'Edit', 'icon': 'pencil', 'action': {'type': 'navigate', 'screen': 'edit'}},
          {'label': 'Delete', 'icon': 'trash', 'action': {'type': 'delete_entry'}},
        ],
      });

      final menu = node as ActionMenuNode;
      expect(menu.icon, 'gear');
      expect(menu.items.length, 2);
      expect(menu.items[0]['label'], 'Edit');
      expect(menu.items[1]['label'], 'Delete');
    });
  });

  group('action_menu builder', () {
    const testModule = Module(id: 'test', name: 'Test');

    setUpAll(() {
      WidgetRegistry.instance.registerDefaults();
    });

    Widget buildWidget({
      ActionMenuNode? node,
      void Function(String, {Map<String, dynamic> params})? onNavigate,
    }) {
      final menuNode = node ??
          const ActionMenuNode(
            items: [
              {'label': 'Settings', 'action': {'type': 'navigate', 'screen': '_settings'}},
              {'label': 'About', 'action': {'type': 'navigate', 'screen': '_about'}},
            ],
          );

      final ctx = RenderContext(
        module: testModule,
        onFormValueChanged: (_, _) {},
        onNavigateToScreen: onNavigate ??
            (_, {Map<String, dynamic> params = const {}}) {},
      );

      return MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: WidgetRegistry.instance.build(menuNode, ctx),
        ),
      );
    }

    testWidgets('renders popup menu button with icon', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.byType(PopupMenuButton<int>), findsOneWidget);
    });

    testWidgets('shows menu items on tap', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Tap the popup menu trigger
      await tester.tap(find.byType(PopupMenuButton<int>));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
    });

    testWidgets('selecting item dispatches action', (tester) async {
      String? navigatedScreen;

      await tester.pumpWidget(buildWidget(
        onNavigate: (screen, {Map<String, dynamic> params = const {}}) {
          navigatedScreen = screen;
        },
      ));
      await tester.pumpAndSettle();

      // Open menu
      await tester.tap(find.byType(PopupMenuButton<int>));
      await tester.pumpAndSettle();

      // Tap first item
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(navigatedScreen, '_settings');
    });

    testWidgets('registry resolves action_menu', (tester) async {
      const node = ActionMenuNode(items: []);
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
