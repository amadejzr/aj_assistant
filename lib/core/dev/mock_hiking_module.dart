import '../../features/schema/models/field_definition.dart';
import '../../features/schema/models/field_type.dart';
import '../../features/schema/models/module_schema.dart';
import '../models/module.dart';

Module createMockHikingModule() {
  const allFields = [
    'name',
    'date',
    'notes',
    'status',
    'rating',
    'difficulty',
    'highlight',
  ];

  return const Module(
    id: 'hiking',
    name: 'Hiking',
    description: 'Plan hikes & track your trails',
    icon: 'mountains',
    color: '#4A7C59',
    sortOrder: 1,
    version: 1,
    guide: [
      {'title': 'Planning Hikes', 'body': 'Add a hike with status "planned" and a date to schedule it, or leave the date blank to save it as an idea for later.'},
      {'title': 'After the Trail', 'body': 'Switch a hike\'s status to "completed" to unlock rating, difficulty, and highlight fields. Record how it went while it\'s fresh.'},
      {'title': 'Calendar View', 'body': 'Tap "View Calendar" on the Upcoming tab to see all your hikes on a calendar. Tap any date to jump to that entry.'},
    ],
    schemas: {
      'default': ModuleSchema(
        label: 'Hike',
        icon: 'mountains',
        fields: {
          'name': FieldDefinition(
            key: 'name',
            type: FieldType.text,
            label: 'Trail Name',
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
          'status': FieldDefinition(
            key: 'status',
            type: FieldType.enumType,
            label: 'Status',
            options: ['planned', 'completed'],
          ),
          // ─── Post-hike fields ───
          'rating': FieldDefinition(
            key: 'rating',
            type: FieldType.rating,
            label: 'Rating',
            constraints: {'min': 1, 'max': 5},
          ),
          'difficulty': FieldDefinition(
            key: 'difficulty',
            type: FieldType.enumType,
            label: 'Difficulty',
            options: ['Easy', 'Moderate', 'Hard'],
          ),
          'highlight': FieldDefinition(
            key: 'highlight',
            type: FieldType.text,
            label: 'Best Moment',
          ),
        },
      ),
    },
    screens: {
      // ─── Main: two-tab overview ───
      'main': {
        'id': 'main',
        'type': 'tab_screen',
        'title': 'Hiking',
        'tabs': [
          {
            'label': 'Upcoming',
            'icon': 'compass',
            'content': {
              'type': 'scroll_column',
              'children': [
                {
                  'type': 'row',
                  'children': [
                    {
                      'type': 'stat_card',
                      'label': 'Planned',
                      'expression': 'count(where(status, ==, planned))',
                    },
                    {
                      'type': 'stat_card',
                      'label': 'This Month',
                      'expression':
                          'count(where(status, ==, planned), period(month))',
                    },
                  ],
                },
                {
                  'type': 'button',
                  'label': 'View Calendar',
                  'style': 'outlined',
                  'action': {
                    'type': 'navigate',
                    'screen': 'calendar',
                  },
                },
                {
                  'type': 'section',
                  'title': 'Scheduled',
                  'children': [
                    {
                      'type': 'entry_list',
                      'filter': [
                        {'field': 'status', 'op': '==', 'value': 'planned'},
                        {'field': 'date', 'op': 'not_null'},
                      ],
                      'query': {
                        'orderBy': 'date',
                        'direction': 'asc',
                      },
                      'itemLayout': {
                        'type': 'entry_card',
                        'title': '{{name}}',
                        'subtitle': '{{date}}',
                        'onTap': {
                          'type': 'navigate',
                          'screen': 'edit_entry',
                          'forwardFields': allFields,
                        },
                        'swipeActions': {
                          'right': {
                            'type': 'delete_entry',
                            'confirm': true,
                            'confirmMessage': 'Remove this hike?',
                          },
                        },
                      },
                    },
                  ],
                },
                {
                  'type': 'section',
                  'title': 'Ideas',
                  'children': [
                    {
                      'type': 'entry_list',
                      'filter': [
                        {'field': 'status', 'op': '==', 'value': 'planned'},
                        {'field': 'date', 'op': 'is_null'},
                      ],
                      'itemLayout': {
                        'type': 'entry_card',
                        'title': '{{name}}',
                        'subtitle': '{{notes}}',
                        'onTap': {
                          'type': 'navigate',
                          'screen': 'edit_entry',
                          'forwardFields': allFields,
                        },
                        'swipeActions': {
                          'right': {
                            'type': 'delete_entry',
                            'confirm': true,
                            'confirmMessage': 'Remove this hike idea?',
                          },
                        },
                      },
                    },
                  ],
                },
              ],
            },
          },
          {
            'label': 'Done',
            'icon': 'check_circle',
            'content': {
              'type': 'scroll_column',
              'children': [
                {
                  'type': 'row',
                  'children': [
                    {
                      'type': 'stat_card',
                      'label': 'Completed',
                      'expression': 'count(where(status, ==, completed))',
                    },
                  ],
                },
                {
                  'type': 'section',
                  'title': 'Trail Log',
                  'children': [
                    {
                      'type': 'entry_list',
                      'filter': [
                        {'field': 'status', 'op': '==', 'value': 'completed'},
                      ],
                      'query': {
                        'orderBy': 'date',
                        'direction': 'desc',
                      },
                      'itemLayout': {
                        'type': 'entry_card',
                        'title': '{{name}}',
                        'subtitle': '{{difficulty}}',
                        'trailing': '{{rating}}',
                        'trailingFormat': 'rating',
                        'onTap': {
                          'type': 'navigate',
                          'screen': 'edit_entry',
                          'forwardFields': allFields,
                        },
                        'swipeActions': {
                          'right': {
                            'type': 'delete_entry',
                            'confirm': true,
                            'confirmMessage': 'Delete this hike log?',
                          },
                        },
                      },
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
          'action': {'type': 'navigate', 'screen': 'add_entry'},
        },
      },

      // ─── Calendar: all entries, tappable ───
      'calendar': {
        'id': 'calendar',
        'type': 'screen',
        'title': 'Calendar',
        'layout': {
          'type': 'scroll_column',
          'children': [
            {
              'type': 'date_calendar',
              'dateField': 'date',
              'onEntryTap': {
                'screen': 'edit_entry',
              },
              'forwardFields': allFields,
            },
          ],
        },
      },

      // ─── Add: status selector up top, post-hike fields appear for "completed" ───
      'add_entry': {
        'id': 'add_entry',
        'type': 'form_screen',
        'title': 'New Hike',
        'submitLabel': 'Save',
        'defaults': {'status': 'planned'},
        'children': [
          {'type': 'enum_selector', 'fieldKey': 'status'},
          {'type': 'text_input', 'fieldKey': 'name'},
          {'type': 'date_picker', 'fieldKey': 'date'},
          {'type': 'text_input', 'fieldKey': 'notes', 'multiline': true},
          {
            'type': 'conditional',
            'condition': {
              'field': 'status',
              'op': '==',
              'value': 'completed',
            },
            'then': [
              {
                'type': 'section',
                'title': 'How was it?',
                'children': [
                  {'type': 'rating_input', 'fieldKey': 'rating'},
                  {'type': 'enum_selector', 'fieldKey': 'difficulty'},
                  {
                    'type': 'text_input',
                    'fieldKey': 'highlight',
                    'multiline': true,
                  },
                ],
              },
            ],
          },
        ],
      },

      // ─── Edit: same layout, pre-filled from entry data ───
      'edit_entry': {
        'id': 'edit_entry',
        'type': 'form_screen',
        'title': 'Edit Hike',
        'editLabel': 'Update',
        'children': [
          {'type': 'enum_selector', 'fieldKey': 'status'},
          {'type': 'text_input', 'fieldKey': 'name'},
          {'type': 'date_picker', 'fieldKey': 'date'},
          {'type': 'text_input', 'fieldKey': 'notes', 'multiline': true},
          {
            'type': 'conditional',
            'condition': {
              'field': 'status',
              'op': '==',
              'value': 'completed',
            },
            'then': [
              {
                'type': 'section',
                'title': 'How was it?',
                'children': [
                  {'type': 'rating_input', 'fieldKey': 'rating'},
                  {'type': 'enum_selector', 'fieldKey': 'difficulty'},
                  {
                    'type': 'text_input',
                    'fieldKey': 'highlight',
                    'multiline': true,
                  },
                ],
              },
            ],
          },
        ],
      },
    },
  );
}
