import '../models/field_definition.dart';
import '../models/field_type.dart';
import '../models/module.dart';
import '../models/module_schema.dart';

Module createMockFitnessModule() {
  return const Module(
    id: 'fitness',
    name: 'Fitness',
    description: 'Plan and log your workouts',
    icon: 'barbell',
    color: '#D94E33',
    sortOrder: 0,
    schema: ModuleSchema(
      version: 1,
      fields: {
        'activityType': FieldDefinition(
          key: 'activityType',
          type: FieldType.enumType,
          label: 'Activity',
          required: true,
          options: ['Fitness', 'Running', 'Padel'],
        ),
        'date': FieldDefinition(
          key: 'date',
          type: FieldType.datetime,
          label: 'Date',
          required: true,
        ),
        'entryType': FieldDefinition(
          key: 'entryType',
          type: FieldType.enumType,
          label: 'Type',
          options: ['plan', 'log'],
        ),
        'plan': FieldDefinition(
          key: 'plan',
          type: FieldType.text,
          label: 'What are you going to do?',
        ),
        'log': FieldDefinition(
          key: 'log',
          type: FieldType.text,
          label: 'What did you do?',
        ),
        'duration': FieldDefinition(
          key: 'duration',
          type: FieldType.number,
          label: 'Duration (min)',
          constraints: {'min': 1, 'max': 600},
        ),
        'feeling': FieldDefinition(
          key: 'feeling',
          type: FieldType.enumType,
          label: 'How did it go?',
          options: ['Great', 'Good', 'OK', 'Tough', 'Bad'],
        ),
        'notes': FieldDefinition(
          key: 'notes',
          type: FieldType.text,
          label: 'Notes',
        ),
      },
    ),
    screens: {
      // ─── Main: tabbed screen with Activities, Calendar, Stats ───
      'main': {
        'type': 'tab_screen',
        'title': 'Fitness',
        'tabs': [
          {
            'label': 'Activities',
            'icon': 'activity',
            'content': {
              'type': 'scroll_column',
              'children': [
                {
                  'type': 'card_grid',
                  'fieldKey': 'activityType',
                  'action': {
                    'type': 'navigate',
                    'screen': 'activity_detail',
                    'paramKey': 'activityType',
                  },
                },
              ],
            },
          },
          {
            'label': 'Calendar',
            'icon': 'calendar',
            'content': {
              'type': 'scroll_column',
              'children': [
                {
                  'type': 'date_calendar',
                  'dateField': 'date',
                },
              ],
            },
          },
          {
            'label': 'Stats',
            'icon': 'stats',
            'content': {
              'type': 'scroll_column',
              'children': [
                {
                  'type': 'section',
                  'title': 'Overview',
                  'children': [
                    {
                      'type': 'row',
                      'children': [
                        {
                          'type': 'stat_card',
                          'label': 'Total Workouts',
                          'stat': 'count',
                          'filter': {'entryType': 'log'},
                        },
                        {
                          'type': 'stat_card',
                          'label': 'Current Streak',
                          'stat': 'streak',
                          'filter': {'entryType': 'log'},
                        },
                      ],
                    },
                    {
                      'type': 'row',
                      'children': [
                        {
                          'type': 'stat_card',
                          'label': 'This Week',
                          'stat': 'this_week',
                          'filter': {'entryType': 'log'},
                        },
                        {
                          'type': 'stat_card',
                          'label': 'This Month',
                          'stat': 'this_month',
                          'filter': {'entryType': 'log'},
                        },
                      ],
                    },
                  ],
                },
                {
                  'type': 'section',
                  'title': 'Duration',
                  'children': [
                    {
                      'type': 'row',
                      'children': [
                        {
                          'type': 'stat_card',
                          'label': 'Total Time',
                          'stat': 'total_duration',
                          'format': 'minutes',
                          'filter': {'entryType': 'log'},
                        },
                        {
                          'type': 'stat_card',
                          'label': 'Avg Duration',
                          'stat': 'avg_duration',
                          'format': 'minutes',
                          'filter': {'entryType': 'log'},
                        },
                      ],
                    },
                  ],
                },
              ],
            },
          },
        ],
        'fab': {
          'type': 'fab',
          'icon': 'add',
          'action': {'type': 'navigate', 'screen': 'plan'},
        },
      },

      // ─── Activity Detail: filtered by activityType from screenParams ───
      'activity_detail': {
        'type': 'tab_screen',
        'title': 'Activity',
        'tabs': [
          {
            'label': 'Activity',
            'icon': 'activity',
            'content': {
              'type': 'scroll_column',
              'children': [
                {
                  'type': 'section',
                  'title': 'Planned',
                  'children': [
                    {
                      'type': 'entry_list',
                      'query': {'orderBy': 'date', 'direction': 'desc', 'limit': 20},
                      'filter': {'entryType': 'plan'},
                      'itemLayout': {
                        'type': 'entry_card',
                        'title': '{{activityType}}',
                        'subtitle': '{{plan}}',
                        'trailing': '{{date}}',
                      },
                    },
                  ],
                },
                {
                  'type': 'section',
                  'title': 'Logged',
                  'children': [
                    {
                      'type': 'entry_list',
                      'query': {'orderBy': 'date', 'direction': 'desc', 'limit': 20},
                      'filter': {'entryType': 'log'},
                      'itemLayout': {
                        'type': 'entry_card',
                        'title': '{{activityType}}',
                        'subtitle': '{{log}}',
                        'trailing': '{{feeling}}',
                      },
                    },
                  ],
                },
              ],
            },
          },
          {
            'label': 'Stats',
            'icon': 'stats',
            'content': {
              'type': 'scroll_column',
              'children': [
                {
                  'type': 'section',
                  'title': 'Overview',
                  'children': [
                    {
                      'type': 'row',
                      'children': [
                        {
                          'type': 'stat_card',
                          'label': 'Total',
                          'stat': 'count',
                          'filter': {'entryType': 'log'},
                        },
                        {
                          'type': 'stat_card',
                          'label': 'Streak',
                          'stat': 'streak',
                          'filter': {'entryType': 'log'},
                        },
                      ],
                    },
                    {
                      'type': 'row',
                      'children': [
                        {
                          'type': 'stat_card',
                          'label': 'This Week',
                          'stat': 'this_week',
                          'filter': {'entryType': 'log'},
                        },
                        {
                          'type': 'stat_card',
                          'label': 'This Month',
                          'stat': 'this_month',
                          'filter': {'entryType': 'log'},
                        },
                      ],
                    },
                  ],
                },
                {
                  'type': 'section',
                  'title': 'Duration',
                  'children': [
                    {
                      'type': 'row',
                      'children': [
                        {
                          'type': 'stat_card',
                          'label': 'Total Time',
                          'stat': 'total_duration',
                          'format': 'minutes',
                          'filter': {'entryType': 'log'},
                        },
                        {
                          'type': 'stat_card',
                          'label': 'Avg Duration',
                          'stat': 'avg_duration',
                          'format': 'minutes',
                          'filter': {'entryType': 'log'},
                        },
                      ],
                    },
                  ],
                },
              ],
            },
          },
        ],
        'fab': {
          'type': 'fab',
          'icon': 'add',
          'action': {'type': 'navigate', 'screen': 'plan'},
        },
      },

      // ─── Plan screen ───
      'plan': {
        'type': 'form_screen',
        'title': 'Plan Workout',
        'submitLabel': 'Save Plan',
        'defaults': {'entryType': 'plan'},
        'children': [
          {'type': 'enum_selector', 'fieldKey': 'activityType'},
          {'type': 'date_picker', 'fieldKey': 'date'},
          {'type': 'text_input', 'fieldKey': 'plan', 'multiline': true},
          {'type': 'text_input', 'fieldKey': 'notes', 'multiline': true},
        ],
        'nav': {
          'type': 'row',
          'children': [
            {
              'type': 'button',
              'label': 'Log Instead',
              'style': 'outlined',
              'action': {'type': 'navigate', 'screen': 'log'},
            },
          ],
        },
      },

      // ─── Log screen ───
      'log': {
        'type': 'form_screen',
        'title': 'Log Workout',
        'submitLabel': 'Save Log',
        'defaults': {'entryType': 'log'},
        'children': [
          {'type': 'enum_selector', 'fieldKey': 'activityType'},
          {'type': 'date_picker', 'fieldKey': 'date'},
          {'type': 'text_input', 'fieldKey': 'log', 'multiline': true},
          {
            'type': 'row',
            'children': [
              {'type': 'number_input', 'fieldKey': 'duration'},
              {'type': 'enum_selector', 'fieldKey': 'feeling'},
            ],
          },
          {'type': 'text_input', 'fieldKey': 'notes', 'multiline': true},
        ],
        'nav': {
          'type': 'row',
          'children': [
            {
              'type': 'button',
              'label': 'Plan Instead',
              'style': 'outlined',
              'action': {'type': 'navigate', 'screen': 'plan'},
            },
          ],
        },
      },
    },
  );
}
