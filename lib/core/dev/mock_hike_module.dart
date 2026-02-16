import '../models/field_definition.dart';
import '../models/field_type.dart';
import '../models/module.dart';
import '../models/module_schema.dart';

Module createMockHikeModule() {
  return const Module(
    id: 'hikes',
    name: 'Hikes',
    description: 'Plan and log your hikes',
    icon: 'mountains',
    color: '#5B8C5A',
    sortOrder: 2,
    schema: ModuleSchema(
      version: 1,
      fields: {
        'name': FieldDefinition(
          key: 'name',
          type: FieldType.text,
          label: 'Trail Name',
          required: true,
        ),
        'location': FieldDefinition(
          key: 'location',
          type: FieldType.text,
          label: 'Location',
        ),
        'date': FieldDefinition(
          key: 'date',
          type: FieldType.datetime,
          label: 'Date',
        ),
        'difficulty': FieldDefinition(
          key: 'difficulty',
          type: FieldType.enumType,
          label: 'Difficulty',
          options: ['Easy', 'Moderate', 'Hard'],
        ),
        'distance': FieldDefinition(
          key: 'distance',
          type: FieldType.number,
          label: 'Distance (km)',
          constraints: {'min': 0},
        ),
        'duration': FieldDefinition(
          key: 'duration',
          type: FieldType.number,
          label: 'Duration (min)',
          constraints: {'min': 0},
        ),
        'feeling': FieldDefinition(
          key: 'feeling',
          type: FieldType.enumType,
          label: 'How was it?',
          options: ['Amazing', 'Great', 'Good', 'Tough'],
        ),
        'notes': FieldDefinition(
          key: 'notes',
          type: FieldType.text,
          label: 'Notes',
        ),
        'completed': FieldDefinition(
          key: 'completed',
          type: FieldType.text,
          label: 'Completed',
        ),
      },
    ),
    screens: {
      // ─── Main: Home / Calendar / Stats ───
      'main': {
        'type': 'tab_screen',
        'title': 'Hikes',
        'tabs': [
          // ── Home ──
          {
            'label': 'Home',
            'icon': 'activity',
            'content': {
              'type': 'scroll_column',
              'children': [
                // Upcoming (planned but not completed)
                {
                  'type': 'section',
                  'title': 'Upcoming',
                  'children': [
                    {
                      'type': 'entry_list',
                      'query': {
                        'orderBy': 'date',
                        'direction': 'asc',
                        'limit': 10,
                      },
                      'filter': {'completed': 'false'},
                      'itemLayout': {
                        'type': 'entry_card',
                        'title': '{{name}}',
                        'subtitle': '{{location}} · {{difficulty}}',
                        'trailing': '{{date}}',
                        'onTap': {
                          'screen': 'hike_detail',
                          'forwardFields': [
                            'name',
                            'location',
                            'date',
                            'difficulty',
                            'distance',
                            'duration',
                            'feeling',
                            'notes',
                            'completed',
                          ],
                        },
                      },
                    },
                  ],
                },
                // Completed hikes
                {
                  'type': 'section',
                  'title': 'Completed',
                  'children': [
                    {
                      'type': 'entry_list',
                      'query': {
                        'orderBy': 'date',
                        'direction': 'desc',
                        'limit': 5,
                      },
                      'filter': {'completed': 'true'},
                      'itemLayout': {
                        'type': 'entry_card',
                        'title': '{{name}}',
                        'subtitle': '{{location}} · {{difficulty}}',
                        'trailing': '{{feeling}}',
                        'onTap': {
                          'screen': 'hike_detail',
                          'forwardFields': [
                            'name',
                            'location',
                            'date',
                            'difficulty',
                            'distance',
                            'duration',
                            'feeling',
                            'notes',
                            'completed',
                          ],
                        },
                        'swipeActions': {
                          'right': {
                            'type': 'delete_entry',
                            'confirm': true,
                            'confirmMessage': 'Delete this hike?',
                          },
                        },
                      },
                    },
                  ],
                },
              ],
            },
          },

          // ── Calendar ──
          {
            'label': 'Calendar',
            'icon': 'calendar',
            'content': {
              'type': 'scroll_column',
              'children': [
                {'type': 'date_calendar', 'dateField': 'date'},
              ],
            },
          },

          // ── Stats ──
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
                          'label': 'Completed',
                          'stat': 'count',
                          'filter': {'completed': 'true'},
                        },
                        {
                          'type': 'stat_card',
                          'label': 'This Month',
                          'stat': 'this_month',
                          'filter': {'completed': 'true'},
                        },
                      ],
                    },
                    {
                      'type': 'row',
                      'children': [
                        {
                          'type': 'stat_card',
                          'label': 'Total Time',
                          'stat': 'total_duration',
                          'format': 'minutes',
                          'filter': {'completed': 'true'},
                        },
                        {
                          'type': 'stat_card',
                          'label': 'Avg Duration',
                          'stat': 'avg_duration',
                          'format': 'minutes',
                          'filter': {'completed': 'true'},
                        },
                      ],
                    },
                    {
                      'type': 'row',
                      'children': [
                        {
                          'type': 'stat_card',
                          'label': 'Total Distance',
                          'stat': 'sum_field',
                          'filter': {
                            'completed': 'true',
                            '_sumField': 'distance',
                          },
                        },
                        {
                          'type': 'stat_card',
                          'label': 'Planned',
                          'stat': 'count',
                          'filter': {'completed': 'false'},
                        },
                      ],
                    },
                  ],
                },
                // Chart — hikes by difficulty
                {
                  'type': 'section',
                  'title': 'By Difficulty',
                  'children': [
                    {
                      'type': 'chart',
                      'chartType': 'donut',
                      'groupBy': 'difficulty',
                      'filter': {'completed': 'true'},
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
          'action': {'type': 'navigate', 'screen': 'plan_hike'},
        },
      },

      // ─── Hike Detail (read-only, with actions) ───
      'hike_detail': {
        'type': 'screen',
        'title': 'Hike Details',
        'children': [
          {
            'type': 'scroll_column',
            'children': [
              {'type': 'text_display', 'text': '{{name}}', 'style': 'headline'},
              {'type': 'text_display', 'text': '{{location}} · {{difficulty}}'},
              {'type': 'text_display', 'text': '{{date}}', 'style': 'caption'},
              {'type': 'divider'},
              // Completion stats — only shown when completed
              {
                'type': 'section',
                'title': 'Stats',
                'visible': {
                  'field': 'completed',
                  'op': '==',
                  'value': 'true',
                },
                'children': [
                  {
                    'type': 'row',
                    'children': [
                      {
                        'type': 'stat_card',
                        'label': 'Distance',
                        'stat': 'param_value',
                        'filter': {'_paramKey': 'distance'},
                      },
                      {
                        'type': 'stat_card',
                        'label': 'Duration',
                        'stat': 'param_value',
                        'format': 'minutes',
                        'filter': {'_paramKey': 'duration'},
                      },
                    ],
                  },
                  {
                    'type': 'text_display',
                    'text': 'Feeling: {{feeling}}',
                    'visible': {
                      'field': 'feeling',
                      'op': 'not_null',
                    },
                  },
                ],
              },
              // Notes section
              {
                'type': 'conditional',
                'condition': {'field': 'notes', 'op': 'not_null'},
                'then': [
                  {
                    'type': 'section',
                    'title': 'Notes',
                    'children': [
                      {'type': 'text_display', 'text': '{{notes}}'},
                    ],
                  },
                ],
              },
              {'type': 'divider'},
              // Actions
              {
                'type': 'button',
                'label': 'Edit Hike',
                'style': 'outlined',
                'action': {
                  'type': 'navigate',
                  'screen': 'edit_hike',
                },
              },
              // Complete button — only when not yet completed
              {
                'type': 'button',
                'label': 'Mark Complete',
                'style': 'primary',
                'visible': {
                  'field': 'completed',
                  'op': '==',
                  'value': 'false',
                },
                'action': {
                  'type': 'navigate',
                  'screen': 'complete_hike',
                },
              },
              {
                'type': 'button',
                'label': 'Delete Hike',
                'style': 'destructive',
                'action': {
                  'type': 'delete_entry',
                  'confirm': true,
                  'confirmMessage': 'Delete this hike permanently?',
                },
              },
            ],
          },
        ],
      },

      // ─── Plan a Hike (creates new entry) ───
      'plan_hike': {
        'type': 'form_screen',
        'title': 'Plan a Hike',
        'submitLabel': 'Save Plan',
        'defaults': {'completed': 'false'},
        'children': [
          {'type': 'text_input', 'fieldKey': 'name'},
          {'type': 'text_input', 'fieldKey': 'location'},
          {'type': 'date_picker', 'fieldKey': 'date'},
          {'type': 'enum_selector', 'fieldKey': 'difficulty'},
          {'type': 'number_input', 'fieldKey': 'distance'},
          {'type': 'text_input', 'fieldKey': 'notes', 'multiline': true},
        ],
      },

      // ─── Edit Hike (updates existing entry) ───
      'edit_hike': {
        'type': 'form_screen',
        'title': 'Edit Hike',
        'submitLabel': 'Save',
        'editLabel': 'Update Hike',
        'children': [
          {'type': 'text_input', 'fieldKey': 'name'},
          {'type': 'text_input', 'fieldKey': 'location'},
          {'type': 'date_picker', 'fieldKey': 'date'},
          {'type': 'enum_selector', 'fieldKey': 'difficulty'},
          {'type': 'number_input', 'fieldKey': 'distance'},
          {'type': 'text_input', 'fieldKey': 'notes', 'multiline': true},
        ],
      },

      // ─── Complete a Hike (updates existing entry) ───
      'complete_hike': {
        'type': 'form_screen',
        'title': 'Complete Hike',
        'submitLabel': 'Mark Complete',
        'defaults': {'completed': 'true'},
        'children': [
          // Pre-filled from plan via screenParams
          {'type': 'text_input', 'fieldKey': 'name'},
          {'type': 'text_input', 'fieldKey': 'location'},
          {'type': 'date_picker', 'fieldKey': 'date'},
          {'type': 'enum_selector', 'fieldKey': 'difficulty'},
          {
            'type': 'row',
            'children': [
              {'type': 'number_input', 'fieldKey': 'distance'},
              {'type': 'number_input', 'fieldKey': 'duration'},
            ],
          },
          {'type': 'enum_selector', 'fieldKey': 'feeling'},
          {'type': 'text_input', 'fieldKey': 'notes', 'multiline': true},
        ],
      },
    },
  );
}
