/// Validates that typed Blueprint builders can reproduce a real template
/// structure (tasks template). Layout and input nodes are typed, display
/// nodes use RawBlueprint as escape hatch.
library;

import 'package:aj_assistant/features/blueprint/models/blueprint.dart';
import 'package:aj_assistant/features/blueprint/models/blueprint_action.dart';
import 'package:flutter_test/flutter_test.dart';

const _allFields = [
  'title',
  'description',
  'priority',
  'status',
  'due_date',
  'project',
];

/// Shared form inputs for add/edit screens.
const _formInputs = <Blueprint>[
  BpTextInput(fieldKey: 'title'),
  BpTextInput(fieldKey: 'description', multiline: true),
  BpEnumSelector(fieldKey: 'priority'),
  BpEnumSelector(fieldKey: 'status'),
  BpDatePicker(fieldKey: 'due_date'),
  BpEnumSelector(fieldKey: 'project'),
];

BpSection _prioritySection(String title, String priority) {
  return BpSection(
    title: title,
    children: [
      RawBlueprint({
        'type': 'entry_list',
        'filter': [
          {'field': 'status', 'op': '!=', 'value': 'done'},
          {'field': 'priority', 'op': '==', 'value': priority},
        ],
        'query': {'orderBy': 'due_date', 'direction': 'asc'},
        'itemLayout': {
          'type': 'entry_card',
          'title': '{{title}}',
          'subtitle': '{{project}}',
          'trailing': '{{due_date}}',
          'trailingFormat': 'relative_date',
          'onTap': const NavigateAction(
            screen: 'edit_entry',
            forwardFields: _allFields,
          ).toJson(),
          'swipeActions': {
            'left': {
              'type': 'update_entry',
              'data': {'status': 'done'},
              'label': 'Done',
            },
            'right': const DeleteEntryAction(
              confirm: true,
              confirmMessage: 'Delete this task?',
            ).toJson(),
          },
        },
      }),
    ],
  );
}

void main() {
  group('Tasks template built with typed builders', () {
    test('main screen produces valid tab_screen JSON', () {
      final mainScreen = BpTabScreen(
        title: 'Tasks',
        tabs: [
          BpTabDef(
            label: 'Active',
            icon: 'pending_actions',
            content: BpScrollColumn(children: [
              const BpRow(children: [
                RawBlueprint({
                  'type': 'stat_card',
                  'label': 'Overdue',
                  'expression':
                      'count(where(status, !=, done), where(due_date, <, today))',
                }),
                RawBlueprint({
                  'type': 'stat_card',
                  'label': 'Due Today',
                  'expression':
                      'count(where(status, !=, done), where(due_date, ==, today))',
                }),
                RawBlueprint({
                  'type': 'stat_card',
                  'label': 'Open',
                  'expression': 'count(where(status, !=, done))',
                }),
              ]),
              const BpButton(
                label: 'View Calendar',
                style: 'outlined',
                action: NavigateAction(screen: 'calendar'),
              ),
              _prioritySection('High Priority', 'high'),
              _prioritySection('Medium Priority', 'medium'),
              _prioritySection('Low Priority', 'low'),
            ]),
          ),
          const BpTabDef(
            label: 'Done',
            icon: 'check_circle',
            content: BpScrollColumn(children: [
              BpRow(children: [
                RawBlueprint({
                  'type': 'stat_card',
                  'label': 'Completed',
                  'expression': 'count(where(status, ==, done))',
                }),
                RawBlueprint({
                  'type': 'stat_card',
                  'label': 'This Week',
                  'expression': 'count(where(status, ==, done), period(week))',
                }),
              ]),
              BpSection(
                title: 'Completed Tasks',
                children: [
                  RawBlueprint({
                    'type': 'entry_list',
                    'filter': [
                      {'field': 'status', 'op': '==', 'value': 'done'},
                    ],
                  }),
                ],
              ),
            ]),
          ),
        ],
        fab: const BpFab(
            icon: 'add', action: NavigateAction(screen: 'add_entry')),
      );

      final json = mainScreen.toJson();
      expect(json['type'], 'tab_screen');
      expect(json['title'], 'Tasks');
      expect((json['tabs'] as List).length, 2);

      // Active tab structure
      final activeTab = (json['tabs'] as List)[0] as Map;
      expect(activeTab['label'], 'Active');
      final activeContent = activeTab['content'] as Map;
      expect(activeContent['type'], 'scroll_column');
      final activeChildren = activeContent['children'] as List;
      expect(activeChildren.length, 5);
      expect((activeChildren[0] as Map)['type'], 'row');
      expect((activeChildren[1] as Map)['type'], 'button');
      expect((activeChildren[2] as Map)['type'], 'section');
      expect((activeChildren[2] as Map)['title'], 'High Priority');

      // FAB
      expect(json['fab']['type'], 'fab');
      expect(json['fab']['action']['screen'], 'add_entry');
    });

    test('form screen with typed inputs', () {
      const addEntry = BpFormScreen(
        title: 'New Task',
        submitLabel: 'Save',
        defaults: {'status': 'todo', 'priority': 'medium'},
        children: _formInputs,
      );

      final json = addEntry.toJson();
      expect(json['type'], 'form_screen');
      expect(json['title'], 'New Task');
      expect(json['submitLabel'], 'Save');
      expect(json['defaults'], {'status': 'todo', 'priority': 'medium'});

      final children = json['children'] as List;
      expect(children.length, 6);
      expect(children[0], {'type': 'text_input', 'fieldKey': 'title'});
      expect(children[1], {
        'type': 'text_input',
        'fieldKey': 'description',
        'multiline': true,
      });
      expect(children[2], {'type': 'enum_selector', 'fieldKey': 'priority'});
      expect(children[3], {'type': 'enum_selector', 'fieldKey': 'status'});
      expect(children[4], {'type': 'date_picker', 'fieldKey': 'due_date'});
      expect(children[5], {'type': 'enum_selector', 'fieldKey': 'project'});
    });

    test('edit form reuses same inputs', () {
      const editEntry = BpFormScreen(
        title: 'Edit Task',
        editLabel: 'Update',
        children: _formInputs,
      );

      final json = editEntry.toJson();
      expect(json['type'], 'form_screen');
      expect(json['editLabel'], 'Update');
      expect(json.containsKey('defaults'), false);
      expect((json['children'] as List).length, 6);
    });

    test('calendar screen with raw date_calendar node', () {
      const calendar = BpScreen(
        title: 'Calendar',
        children: [
          BpScrollColumn(children: [
            RawBlueprint({
              'type': 'date_calendar',
              'dateField': 'due_date',
              'onEntryTap': {'screen': 'edit_entry'},
              'forwardFields': _allFields,
            }),
          ]),
        ],
      );

      final json = calendar.toJson();
      expect(json['type'], 'screen');
      expect(json['title'], 'Calendar');
      final scrollCol = (json['children'] as List)[0] as Map;
      expect(scrollCol['type'], 'scroll_column');
      final dateCalendar = (scrollCol['children'] as List)[0] as Map;
      expect(dateCalendar['type'], 'date_calendar');
      expect(dateCalendar['dateField'], 'due_date');
    });

    test('priority section helper produces correct structure', () {
      final section = _prioritySection('High Priority', 'high');
      final json = section.toJson();

      expect(json['type'], 'section');
      expect(json['title'], 'High Priority');
      final entryList = (json['children'] as List)[0] as Map;
      expect(entryList['type'], 'entry_list');
      expect((entryList['filter'] as List)[1]['value'], 'high');

      final onTap = entryList['itemLayout']['onTap'] as Map;
      expect(onTap['type'], 'navigate');
      expect(onTap['screen'], 'edit_entry');
      expect(onTap['forwardFields'], _allFields);

      final deleteAction =
          entryList['itemLayout']['swipeActions']['right'] as Map;
      expect(deleteAction['type'], 'delete_entry');
      expect(deleteAction['confirm'], true);
    });
  });
}
