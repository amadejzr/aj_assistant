/// Validates that typed Blueprint builders can reproduce a real template
/// structure (tasks template). All nodes use typed builders — no RawBlueprint.
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
      BpEntryList(
        filter: [
          const BpFilter(field: 'status', op: '!=', value: 'done'),
          BpFilter(field: 'priority', value: priority),
        ],
        query: const BpQuery(orderBy: 'due_date', direction: 'asc'),
        itemLayout: BpEntryCard(
          title: '{{title}}',
          subtitle: '{{project}}',
          trailing: '{{due_date}}',
          trailingFormat: 'relative_date',
          onTap: const NavigateAction(
            screen: 'edit_entry',
            forwardFields: _allFields,
          ),
          swipeActions: const BpSwipeActions(
            left: UpdateEntryAction(
              data: {'status': 'done'},
              label: 'Done',
            ),
            right: DeleteEntryAction(
              confirm: true,
              confirmMessage: 'Delete this task?',
            ),
          ),
        ),
      ),
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
                BpStatCard(
                  label: 'Overdue',
                  expression:
                      'count(where(status, !=, done), where(due_date, <, today))',
                ),
                BpStatCard(
                  label: 'Due Today',
                  expression:
                      'count(where(status, !=, done), where(due_date, ==, today))',
                ),
                BpStatCard(
                  label: 'Open',
                  expression: 'count(where(status, !=, done))',
                ),
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
                BpStatCard(
                  label: 'Completed',
                  expression: 'count(where(status, ==, done))',
                ),
                BpStatCard(
                  label: 'This Week',
                  expression: 'count(where(status, ==, done), period(week))',
                ),
              ]),
              BpSection(
                title: 'Completed Tasks',
                children: [
                  BpEntryList(
                    filter: [
                      BpFilter(field: 'status', value: 'done'),
                    ],
                  ),
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

      // Stat cards in first row
      final statCards =
          (activeChildren[0] as Map)['children'] as List;
      expect(statCards.length, 3);
      expect(statCards[0]['type'], 'stat_card');
      expect(statCards[0]['label'], 'Overdue');

      // Entry list in priority section
      final highSection = activeChildren[2] as Map;
      final entryList = (highSection['children'] as List)[0] as Map;
      expect(entryList['type'], 'entry_list');
      expect(entryList['itemLayout']['type'], 'entry_card');

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

    test('calendar screen with typed date_calendar', () {
      const calendar = BpScreen(
        title: 'Calendar',
        children: [
          BpScrollColumn(children: [
            BpDateCalendar(
              dateField: 'due_date',
              onEntryTap: NavigateAction(screen: 'edit_entry'),
              forwardFields: _allFields,
            ),
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
      expect(dateCalendar['onEntryTap']['type'], 'navigate');
      expect(dateCalendar['forwardFields'], _allFields);
    });

    test('priority section helper produces correct structure', () {
      final section = _prioritySection('High Priority', 'high');
      final json = section.toJson();

      expect(json['type'], 'section');
      expect(json['title'], 'High Priority');
      final entryList = (json['children'] as List)[0] as Map;
      expect(entryList['type'], 'entry_list');
      expect((entryList['filter'] as List)[1]['value'], 'high');

      final itemLayout = entryList['itemLayout'] as Map;
      expect(itemLayout['type'], 'entry_card');
      expect(itemLayout['title'], '{{title}}');

      final onTap = itemLayout['onTap'] as Map;
      expect(onTap['type'], 'navigate');
      expect(onTap['screen'], 'edit_entry');
      expect(onTap['forwardFields'], _allFields);

      final swipeActions = itemLayout['swipeActions'] as Map;
      expect(swipeActions['left']['type'], 'update_entry');
      expect(swipeActions['left']['data'], {'status': 'done'});
      expect(swipeActions['right']['type'], 'delete_entry');
      expect(swipeActions['right']['confirm'], true);
    });
  });
}
