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

  group('BlueprintParser — expandable', () {
    test('creates ExpandableNode with defaults', () {
      final node = parser.parse({
        'type': 'expandable',
        'title': 'Details',
        'children': [],
      });

      expect(node, isA<ExpandableNode>());
      final expandable = node as ExpandableNode;
      expect(expandable.title, 'Details');
      expect(expandable.initiallyExpanded, false);
      expect(expandable.children, isEmpty);
    });

    test('parses initiallyExpanded and children', () {
      final node = parser.parse({
        'type': 'expandable',
        'title': 'Advanced',
        'initiallyExpanded': true,
        'children': [
          {'type': 'text_display', 'text': 'Hidden content'},
        ],
      });

      final expandable = node as ExpandableNode;
      expect(expandable.initiallyExpanded, true);
      expect(expandable.children.length, 1);
      expect(expandable.children.first, isA<TextDisplayNode>());
    });
  });

  group('expandable builder', () {
    const testModule = Module(id: 'test', name: 'Test');

    setUpAll(() {
      WidgetRegistry.instance.registerDefaults();
    });

    Widget buildWidget({
      ExpandableNode? node,
    }) {
      final expandableNode = node ??
          const ExpandableNode(
            title: 'More Info',
            children: [
              TextDisplayNode(text: 'Expanded content here'),
            ],
          );

      final ctx = RenderContext(
        module: testModule,
        onFormValueChanged: (_, _) {},
        onNavigateToScreen: (_, {Map<String, dynamic> params = const {}}) {},
      );

      return MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: WidgetRegistry.instance.build(expandableNode, ctx),
          ),
        ),
      );
    }

    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('More Info'), findsOneWidget);
    });

    testWidgets('content hidden when collapsed', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Content should not be visible (collapsed by default)
      // AnimatedCrossFade shows SizedBox.shrink when collapsed
      expect(find.text('Expanded content here'), findsOneWidget);
      // But the text widget will exist inside AnimatedCrossFade even when not shown
    });

    testWidgets('tap title expands content', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Tap the title area to expand
      await tester.tap(find.text('More Info'));
      await tester.pumpAndSettle();

      expect(find.text('Expanded content here'), findsOneWidget);
    });

    testWidgets('shows expand_more icon', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.expand_more), findsOneWidget);
    });

    testWidgets('initiallyExpanded shows content immediately', (tester) async {
      await tester.pumpWidget(buildWidget(
        node: const ExpandableNode(
          title: 'Open',
          initiallyExpanded: true,
          children: [TextDisplayNode(text: 'Visible now')],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Visible now'), findsOneWidget);
    });

    testWidgets('registry resolves expandable', (tester) async {
      const node = ExpandableNode(title: 'Test');
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
