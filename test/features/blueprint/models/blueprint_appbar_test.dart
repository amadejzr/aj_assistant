import 'package:aj_assistant/features/blueprint/models/blueprint.dart';
import 'package:aj_assistant/features/blueprint/models/blueprint_action.dart';
import 'package:aj_assistant/features/blueprint/renderer/blueprint_node.dart';
import 'package:aj_assistant/features/blueprint/renderer/blueprint_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BpAppBar', () {
    test('toJson with title only', () {
      const appBar = BpAppBar(title: 'Expenses');
      expect(appBar.toJson(), {
        'type': 'app_bar',
        'title': 'Expenses',
      });
    });

    test('toJson with actions', () {
      const appBar = BpAppBar(
        title: 'Tasks',
        actions: [
          BpIconButton(
            icon: 'search',
            action: NavigateAction(screen: 'search'),
          ),
        ],
      );
      expect(appBar.toJson(), {
        'type': 'app_bar',
        'title': 'Tasks',
        'actions': [
          {
            'type': 'icon_button',
            'icon': 'search',
            'action': {'type': 'navigate', 'screen': 'search'},
          },
        ],
      });
    });

    test('toJson showBack false', () {
      const appBar = BpAppBar(title: 'Home', showBack: false);
      expect(appBar.toJson(), {
        'type': 'app_bar',
        'title': 'Home',
        'showBack': false,
      });
    });

    test('toJson omits defaults', () {
      const appBar = BpAppBar();
      final json = appBar.toJson();
      expect(json, {'type': 'app_bar'});
      expect(json.containsKey('title'), isFalse);
      expect(json.containsKey('actions'), isFalse);
      expect(json.containsKey('showBack'), isFalse);
    });

    test('equality', () {
      const a = BpAppBar(title: 'X', showBack: false);
      const b = BpAppBar(title: 'X', showBack: false);
      expect(a, equals(b));
    });
  });

  group('BpScreen with appBar', () {
    test('toJson includes appBar', () {
      const screen = BpScreen(
        title: 'Expenses',
        appBar: BpAppBar(
          title: 'My Expenses',
          actions: [
            BpIconButton(
              icon: 'search',
              action: NavigateAction(screen: 'search'),
            ),
          ],
        ),
        children: [BpScrollColumn()],
      );
      final json = screen.toJson();
      expect(json['appBar'], isNotNull);
      expect(json['appBar']['title'], 'My Expenses');
      expect(json['appBar']['actions'], hasLength(1));
    });

    test('toJson omits appBar when null', () {
      const screen = BpScreen(title: 'Simple');
      expect(screen.toJson().containsKey('appBar'), isFalse);
    });
  });

  group('BpTabScreen with appBar', () {
    test('toJson includes appBar', () {
      const tabScreen = BpTabScreen(
        title: 'Tracker',
        appBar: BpAppBar(title: 'My Tracker', showBack: false),
        tabs: [
          BpTabDef(label: 'List', content: BpColumn()),
        ],
      );
      final json = tabScreen.toJson();
      expect(json['appBar'], isNotNull);
      expect(json['appBar']['title'], 'My Tracker');
      expect(json['appBar']['showBack'], false);
    });
  });

  group('Parser: AppBarNode', () {
    const parser = BlueprintParser();

    test('parses screen with appBar', () {
      final json = const BpScreen(
        title: 'Test',
        appBar: BpAppBar(
          title: 'Custom Title',
          actions: [
            BpIconButton(
              icon: 'search',
              action: NavigateAction(screen: 'search'),
            ),
          ],
          showBack: false,
        ),
        children: [BpScrollColumn()],
      ).toJson();

      final node = parser.parse(json);
      expect(node, isA<ScreenNode>());
      final screen = node as ScreenNode;
      expect(screen.appBar, isNotNull);
      expect(screen.appBar!.title, 'Custom Title');
      expect(screen.appBar!.showBack, false);
      expect(screen.appBar!.actions, hasLength(1));
    });

    test('parses screen without appBar', () {
      final json = const BpScreen(title: 'Simple').toJson();
      final node = parser.parse(json) as ScreenNode;
      expect(node.appBar, isNull);
    });

    test('parses tab_screen with appBar', () {
      final json = const BpTabScreen(
        title: 'Tabs',
        appBar: BpAppBar(title: 'Custom Tabs'),
        tabs: [
          BpTabDef(label: 'A', content: BpColumn()),
        ],
      ).toJson();

      final node = parser.parse(json) as TabScreenNode;
      expect(node.appBar, isNotNull);
      expect(node.appBar!.title, 'Custom Tabs');
    });
  });
}
