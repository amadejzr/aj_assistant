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

  group('BlueprintParser — icon_button', () {
    test('creates IconButtonNode with defaults', () {
      final node = parser.parse({
        'type': 'icon_button',
        'icon': 'edit',
      });

      expect(node, isA<IconButtonNode>());
      final btn = node as IconButtonNode;
      expect(btn.icon, 'edit');
      expect(btn.tooltip, isNull);
      expect(btn.action, isEmpty);
    });

    test('parses tooltip and action', () {
      final node = parser.parse({
        'type': 'icon_button',
        'icon': 'settings',
        'tooltip': 'Open settings',
        'action': {'type': 'navigate', 'screen': '_settings'},
      });

      final btn = node as IconButtonNode;
      expect(btn.tooltip, 'Open settings');
      expect(btn.action['type'], 'navigate');
      expect(btn.action['screen'], '_settings');
    });
  });

  group('icon_button builder', () {
    const testModule = Module(id: 'test', name: 'Test');

    setUpAll(() {
      WidgetRegistry.instance.registerDefaults();
    });

    Widget buildWidget({
      IconButtonNode? node,
      void Function(String, {Map<String, dynamic> params})? onNavigate,
    }) {
      final btnNode = node ??
          const IconButtonNode(
            icon: 'settings',
            action: {'type': 'navigate', 'screen': '_settings'},
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
          body: WidgetRegistry.instance.build(btnNode, ctx),
        ),
      );
    }

    testWidgets('renders an icon', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Should render some icon widget
      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets('tap dispatches action', (tester) async {
      String? navigatedScreen;

      await tester.pumpWidget(buildWidget(
        onNavigate: (screen, {Map<String, dynamic> params = const {}}) {
          navigatedScreen = screen;
        },
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(InkWell));
      expect(navigatedScreen, '_settings');
    });

    testWidgets('shows tooltip on long press', (tester) async {
      await tester.pumpWidget(buildWidget(
        node: const IconButtonNode(
          icon: 'edit',
          tooltip: 'Edit entry',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(Tooltip), findsOneWidget);
    });

    testWidgets('no tooltip when null', (tester) async {
      await tester.pumpWidget(buildWidget(
        node: const IconButtonNode(icon: 'add'),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(Tooltip), findsNothing);
    });

    testWidgets('registry resolves icon_button', (tester) async {
      const node = IconButtonNode(icon: 'edit');
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
