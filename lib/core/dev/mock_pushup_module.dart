import '../../features/schema/models/field_definition.dart';
import '../../features/schema/models/field_type.dart';
import '../../features/schema/models/module_schema.dart';
import '../models/module.dart';

Module createMockPushupModule() {
  const allFields = ['count', 'date', 'notes'];

  return const Module(
    id: 'pushups',
    name: 'Pushups',
    description: 'Daily pushup tracker',
    icon: 'barbell',
    color: '#D94E33',
    sortOrder: 2,
    settings: {
      'dailyGoal': 40,
    },
    schemas: {
      'default': ModuleSchema(
        label: 'Log',
        icon: 'barbell',
        fields: {
          'count': FieldDefinition(
            key: 'count',
            type: FieldType.number,
            label: 'Pushups',
            required: true,
          ),
          'date': FieldDefinition(
            key: 'date',
            type: FieldType.datetime,
            label: 'Date',
          ),
          'notes': FieldDefinition(
            key: 'notes',
            type: FieldType.text,
            label: 'Notes',
          ),
        },
      ),
    },
    screens: {
      // ─── Main: overview with stats + recent logs ───
      'main': {
        'id': 'main',
        'type': 'screen',
        'title': 'Pushups',
        'layout': {
          'type': 'scroll_column',
          'children': [
            {
              'type': 'row',
              'children': [
                {
                  'type': 'stat_card',
                  'label': 'Today',
                  'expression': 'sum(count, period(today))',
                },
                {
                  'type': 'stat_card',
                  'label': 'Daily Goal',
                  'expression': 'value(dailyGoal)',
                },
              ],
            },
            {
              'type': 'progress_bar',
              'label': 'Today vs Goal',
              'expression':
                  'percentage(sum(count, period(today)), value(dailyGoal))',
              'format': 'percentage',
            },
            {
              'type': 'row',
              'children': [
                {
                  'type': 'stat_card',
                  'label': 'Total',
                  'expression': 'sum(count)',
                },
                {
                  'type': 'stat_card',
                  'label': 'Streak',
                  'expression': 'streak(date)',
                },
              ],
            },
            {
              'type': 'button',
              'label': 'Change Daily Goal',
              'style': 'outlined',
              'action': {
                'type': 'navigate',
                'screen': 'edit_goal',
                'params': {'_settingsMode': true},
              },
            },
            {
              'type': 'section',
              'title': 'Recent',
              'children': [
                {
                  'type': 'entry_list',
                  'query': {
                    'orderBy': 'date',
                    'direction': 'desc',
                    'limit': 20,
                  },
                  'itemLayout': {
                    'type': 'entry_card',
                    'title': '{{count}} pushups',
                    'subtitle': '{{date}}',
                    'trailing': '{{notes}}',
                    'onTap': {
                      'type': 'navigate',
                      'screen': 'edit_entry',
                      'forwardFields': allFields,
                    },
                    'swipeActions': {
                      'right': {
                        'type': 'delete_entry',
                        'confirm': true,
                        'confirmMessage': 'Delete this log?',
                      },
                    },
                  },
                },
              ],
            },
          ],
        },
        'fab': {
          'type': 'fab',
          'icon': 'add',
          'action': {'type': 'navigate', 'screen': 'add_entry'},
        },
      },

      // ─── Change daily goal ───
      'edit_goal': {
        'id': 'edit_goal',
        'type': 'form_screen',
        'title': 'Daily Goal',
        'submitLabel': 'Save',
        'children': [
          {'type': 'number_input', 'fieldKey': 'dailyGoal', 'label': 'Pushups per day'},
        ],
      },

      // ─── Add entry ───
      'add_entry': {
        'id': 'add_entry',
        'type': 'form_screen',
        'title': 'Log Pushups',
        'submitLabel': 'Save',
        'children': [
          {'type': 'number_input', 'fieldKey': 'count'},
          {'type': 'date_picker', 'fieldKey': 'date'},
          {'type': 'text_input', 'fieldKey': 'notes', 'multiline': true},
        ],
      },

      // ─── Edit entry ───
      'edit_entry': {
        'id': 'edit_entry',
        'type': 'form_screen',
        'title': 'Edit Log',
        'editLabel': 'Update',
        'children': [
          {'type': 'number_input', 'fieldKey': 'count'},
          {'type': 'date_picker', 'fieldKey': 'date'},
          {'type': 'text_input', 'fieldKey': 'notes', 'multiline': true},
        ],
      },
    },
  );
}
