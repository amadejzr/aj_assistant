import 'package:bowerlab/core/models/module.dart';
import 'package:bowerlab/core/theme/app_theme.dart';
import 'package:bowerlab/features/blueprint/renderer/blueprint_node.dart';
import 'package:bowerlab/features/blueprint/renderer/blueprint_parser.dart';
import 'package:bowerlab/features/blueprint/renderer/render_context.dart';
import 'package:bowerlab/features/blueprint/renderer/widget_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = BlueprintParser();

  group('BlueprintParser — badge', () {
    test('creates BadgeNode with defaults', () {
      final node = parser.parse({
        'type': 'badge',
        'text': 'Active',
      });

      expect(node, isA<BadgeNode>());
      final badge = node as BadgeNode;
      expect(badge.text, 'Active');
      expect(badge.variant, 'default');
      expect(badge.expression, isNull);
    });

    test('parses variant and expression', () {
      final node = parser.parse({
        'type': 'badge',
        'text': 'Urgent',
        'variant': 'accent',
        'expression': 'count(period(today))',
      });

      final badge = node as BadgeNode;
      expect(badge.variant, 'accent');
      expect(badge.expression, 'count(period(today))');
    });
  });

  group('badge builder', () {
    const testModule = Module(id: 'test', name: 'Test');

    setUpAll(() {
      WidgetRegistry.instance.registerDefaults();
    });

    Widget buildWidget({
      BadgeNode? node,
      Map<String, dynamic> resolvedExpressions = const {},
    }) {
      final badgeNode = node ?? const BadgeNode(text: 'Active');

      final ctx = RenderContext(
        module: testModule,
        onFormValueChanged: (_, _) {},
        onNavigateToScreen: (_, {Map<String, dynamic> params = const {}}) {},
        resolvedExpressions: resolvedExpressions,
      );

      return MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: WidgetRegistry.instance.build(badgeNode, ctx),
        ),
      );
    }

    testWidgets('renders badge text', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('shows resolved expression value when available',
        (tester) async {
      await tester.pumpWidget(buildWidget(
        node: const BadgeNode(
          text: 'fallback',
          expression: 'count(period(today))',
        ),
        resolvedExpressions: {'count(period(today))': 5},
      ));
      await tester.pumpAndSettle();

      expect(find.text('5'), findsOneWidget);
      expect(find.text('fallback'), findsNothing);
    });

    testWidgets('falls back to text when expression not resolved',
        (tester) async {
      await tester.pumpWidget(buildWidget(
        node: const BadgeNode(
          text: 'N/A',
          expression: 'count(period(today))',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('N/A'), findsOneWidget);
    });

    testWidgets('badge is rotated (hanko style)', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Transform.rotate wraps the container — verify Transform exists
      expect(find.byType(Transform), findsWidgets);
    });

    testWidgets('registry resolves badge', (tester) async {
      const node = BadgeNode(text: 'Test');
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
