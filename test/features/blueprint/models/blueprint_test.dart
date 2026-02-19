import 'package:aj_assistant/features/blueprint/models/blueprint.dart';
import 'package:aj_assistant/features/blueprint/models/blueprint_action.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BpScreen', () {
    test('minimal screen', () {
      const screen = BpScreen(title: 'Home');
      expect(screen.toJson(), {
        'type': 'screen',
        'title': 'Home',
        'children': [],
      });
    });

    test('screen with children and fab', () {
      const screen = BpScreen(
        title: 'Tasks',
        children: [BpSection(title: 'Urgent')],
        fab: BpFab(icon: 'add', action: NavigateAction(screen: 'add')),
      );
      final json = screen.toJson();
      expect(json['type'], 'screen');
      expect(json['title'], 'Tasks');
      expect((json['children'] as List).length, 1);
      expect(json['fab']['icon'], 'add');
    });
  });

  group('BpFormScreen', () {
    test('form with defaults and children', () {
      const form = BpFormScreen(
        title: 'New Task',
        submitLabel: 'Save',
        defaults: {'status': 'todo'},
        children: [
          RawBlueprint({'type': 'text_input', 'fieldKey': 'title'}),
        ],
      );
      final json = form.toJson();
      expect(json['type'], 'form_screen');
      expect(json['title'], 'New Task');
      expect(json['submitLabel'], 'Save');
      expect(json['defaults'], {'status': 'todo'});
      expect((json['children'] as List).length, 1);
    });

    test('edit form with editLabel', () {
      const form = BpFormScreen(
        title: 'Edit Task',
        editLabel: 'Update',
      );
      expect(form.toJson()['editLabel'], 'Update');
    });
  });

  group('BpTabScreen', () {
    test('tab screen with two tabs', () {
      const tabs = BpTabScreen(
        title: 'Tasks',
        tabs: [
          BpTabDef(
            label: 'Active',
            icon: 'pending',
            content: BpScrollColumn(),
          ),
          BpTabDef(
            label: 'Done',
            icon: 'check',
            content: BpScrollColumn(),
          ),
        ],
        fab: BpFab(icon: 'add', action: NavigateAction(screen: 'add')),
      );
      final json = tabs.toJson();
      expect(json['type'], 'tab_screen');
      expect((json['tabs'] as List).length, 2);
      expect((json['tabs'] as List)[0]['label'], 'Active');
      expect(json['fab'], isNotNull);
    });
  });

  group('BpScrollColumn', () {
    test('empty scroll column', () {
      const col = BpScrollColumn();
      expect(col.toJson(), {'type': 'scroll_column', 'children': []});
    });
  });

  group('BpSection', () {
    test('section with title and children', () {
      const section = BpSection(
        title: 'Stats',
        children: [
          RawBlueprint(
              {'type': 'stat_card', 'label': 'Total', 'expression': 'count()'}),
        ],
      );
      final json = section.toJson();
      expect(json['title'], 'Stats');
      expect((json['children'] as List).first['type'], 'stat_card');
    });
  });

  group('BpRow', () {
    test('row serializes children', () {
      const row = BpRow(children: [
        RawBlueprint({'type': 'stat_card', 'label': 'A'}),
        RawBlueprint({'type': 'stat_card', 'label': 'B'}),
      ]);
      expect((row.toJson()['children'] as List).length, 2);
    });
  });

  group('BpColumn', () {
    test('column serializes children', () {
      const col = BpColumn(children: [RawBlueprint({'type': 'divider'})]);
      expect((col.toJson()['children'] as List).length, 1);
    });
  });

  group('BpExpandable', () {
    test('expandable with initiallyExpanded', () {
      const exp = BpExpandable(
        title: 'Details',
        initiallyExpanded: true,
      );
      final json = exp.toJson();
      expect(json['type'], 'expandable');
      expect(json['title'], 'Details');
      expect(json['initiallyExpanded'], true);
    });

    test('initiallyExpanded false is omitted', () {
      const exp = BpExpandable(title: 'Details');
      expect(exp.toJson().containsKey('initiallyExpanded'), false);
    });
  });

  group('BpFab', () {
    test('fab with navigate action', () {
      const fab = BpFab(icon: 'add', action: NavigateAction(screen: 'form'));
      final json = fab.toJson();
      expect(json, {
        'type': 'fab',
        'icon': 'add',
        'action': {'type': 'navigate', 'screen': 'form'},
      });
    });
  });

  group('BpButton', () {
    test('button with style and action', () {
      const btn = BpButton(
        label: 'View Calendar',
        action: NavigateAction(screen: 'calendar'),
        style: 'outlined',
      );
      final json = btn.toJson();
      expect(json['type'], 'button');
      expect(json['label'], 'View Calendar');
      expect(json['style'], 'outlined');
      expect(json['action']['screen'], 'calendar');
    });
  });

  group('RawBlueprint', () {
    test('passes through arbitrary JSON', () {
      const raw = RawBlueprint({
        'type': 'chart',
        'chartType': 'donut',
        'expression': 'group(category, sum(amount))',
      });
      expect(raw.toJson()['type'], 'chart');
      expect(raw.toJson()['chartType'], 'donut');
    });
  });

  group('nested tree', () {
    test('complex nested structure serializes correctly', () {
      const tree = BpScreen(
        title: 'Finance',
        children: [
          BpScrollColumn(children: [
            BpRow(children: [
              RawBlueprint({'type': 'stat_card', 'label': 'Balance'}),
              RawBlueprint({'type': 'stat_card', 'label': 'Spent'}),
            ]),
            BpSection(
              title: 'Recent',
              children: [
                RawBlueprint({'type': 'entry_list', 'filter': []}),
              ],
            ),
          ]),
        ],
        fab: BpFab(icon: 'add', action: NavigateAction(screen: 'add_expense')),
      );

      final json = tree.toJson();
      expect(json['type'], 'screen');
      final scrollCol = (json['children'] as List).first as Map;
      expect(scrollCol['type'], 'scroll_column');
      final row = (scrollCol['children'] as List).first as Map;
      expect(row['type'], 'row');
      expect((row['children'] as List).length, 2);
    });
  });
}
