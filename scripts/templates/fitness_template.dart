const fitnessTemplate = {
  'name': 'Fitness',
  'description': 'Plan workouts, log sessions & crush your goals',
  'longDescription':
      'Plan your workout sessions with exercises and sets, then journal '
      'how you felt after each one. Track fitness goals like marathon '
      'training or strength targets. Works for gym, running, yoga — any activity.',
  'icon': 'barbell',
  'color': '#E65100',
  'category': 'Fitness',
  'tags': ['workout', 'gym', 'running', 'marathon', 'exercise', 'training', 'goals'],
  'featured': true,
  'sortOrder': 2,
  'installCount': 0,
  'version': 1,
  'settings': {},
  'guide': [
    {
      'title': 'Planning Workouts',
      'body':
          'Add a workout with status "Planned" and write out your exercises. '
          'Set a date to schedule it, or leave it blank as a template for later.',
    },
    {
      'title': 'After Your Session',
      'body':
          'Switch status to "Completed" to unlock the journal fields. Rate '
          'how it went, log your feeling, and write a quick reflection while '
          'it\'s fresh.',
    },
    {
      'title': 'Goals',
      'body':
          'Head to the Goals tab to set targets like "Run a marathon" or '
          '"Squat 100kg". Update the status to "Achieved" when you hit them.',
    },
    {
      'title': 'AI Scheduling',
      'body':
          'Chat with the AI to get workout suggestions, schedule sessions, '
          'or adjust your training plan based on how you\'ve been feeling.',
    },
  ],

  // ─── Schemas ───
  'schemas': {
    'workout': {
      'label': 'Workout',
      'icon': 'barbell',
      'fields': {
        'name': {
          'key': 'name',
          'type': 'text',
          'label': 'Workout Name',
          'required': true,
        },
        'type': {
          'key': 'type',
          'type': 'enumType',
          'label': 'Type',
          'options': ['Strength', 'Cardio', 'Flexibility', 'HIIT', 'Mixed'],
        },
        'date': {
          'key': 'date',
          'type': 'datetime',
          'label': 'Date',
        },
        'status': {
          'key': 'status',
          'type': 'enumType',
          'label': 'Status',
          'options': ['Planned', 'Completed', 'Skipped'],
        },
        'exercises': {
          'key': 'exercises',
          'type': 'text',
          'label': 'Exercises',
        },
        'duration': {
          'key': 'duration',
          'type': 'duration',
          'label': 'Duration',
        },
        'distance': {
          'key': 'distance',
          'type': 'number',
          'label': 'Distance (km)',
        },
        'feeling': {
          'key': 'feeling',
          'type': 'enumType',
          'label': 'How I Felt',
          'options': ['Great', 'Good', 'Okay', 'Tired', 'Exhausted'],
        },
        'rating': {
          'key': 'rating',
          'type': 'rating',
          'label': 'Rating',
          'constraints': {'min': 1, 'max': 5},
        },
        'journal': {
          'key': 'journal',
          'type': 'text',
          'label': 'Journal',
        },
      },
    },
    'goal': {
      'label': 'Goal',
      'icon': 'target',
      'fields': {
        'name': {
          'key': 'name',
          'type': 'text',
          'label': 'Goal',
          'required': true,
        },
        'type': {
          'key': 'type',
          'type': 'enumType',
          'label': 'Category',
          'options': ['Endurance', 'Strength', 'Weight', 'Flexibility', 'Custom'],
        },
        'targetDate': {
          'key': 'targetDate',
          'type': 'datetime',
          'label': 'Target Date',
        },
        'target': {
          'key': 'target',
          'type': 'text',
          'label': 'Target',
        },
        'status': {
          'key': 'status',
          'type': 'enumType',
          'label': 'Status',
          'options': ['Active', 'Achieved', 'Abandoned'],
        },
        'notes': {
          'key': 'notes',
          'type': 'text',
          'label': 'Notes',
        },
      },
    },
  },

  // ─── Screens ───
  'screens': {
    // ═══════════════════════════════════════════
    //  MAIN — Three-tab layout
    // ═══════════════════════════════════════════
    'main': {
      'id': 'main',
      'type': 'tab_screen',
      'title': 'Fitness',
      'tabs': [
        // ────────────── Tab 1: Plan ──────────────
        {
          'label': 'Plan',
          'icon': 'calendar',
          'content': {
            'type': 'scroll_column',
            'children': [
              {
                'type': 'row',
                'children': [
                  {
                    'type': 'stat_card',
                    'label': 'Planned This Week',
                    'expression':
                        'count(where(status, ==, Planned), period(week))',
                    'filter': [
                      {'field': 'schemaKey', 'op': '==', 'value': 'workout'},
                    ],
                  },
                  {
                    'type': 'stat_card',
                    'label': 'Completed This Week',
                    'expression':
                        'count(where(status, ==, Completed), period(week))',
                    'filter': [
                      {'field': 'schemaKey', 'op': '==', 'value': 'workout'},
                    ],
                  },
                ],
              },
              {
                'type': 'section',
                'title': 'Upcoming',
                'children': [
                  {
                    'type': 'entry_list',
                    'filter': [
                      {'field': 'schemaKey', 'op': '==', 'value': 'workout'},
                      {'field': 'status', 'op': '==', 'value': 'Planned'},
                    ],
                    'query': {'orderBy': 'date', 'direction': 'asc'},
                    'itemLayout': {
                      'type': 'entry_card',
                      'title': '{{name}}',
                      'subtitle': '{{date}}',
                      'trailing': '{{type}}',
                      'onTap': {
                        'type': 'navigate',
                        'screen': 'edit_workout',
                        'forwardFields': [
                          'name',
                          'type',
                          'date',
                          'status',
                          'exercises',
                          'duration',
                          'distance',
                          'feeling',
                          'rating',
                          'journal',
                        ],
                        'params': {'_schemaKey': 'workout'},
                      },
                      'swipeActions': {
                        'right': {
                          'type': 'delete_entry',
                          'confirm': true,
                          'confirmMessage': 'Remove this workout?',
                        },
                      },
                    },
                  },
                ],
              },
            ],
          },
        },

        // ────────────── Tab 2: Log ──────────────
        {
          'label': 'Log',
          'icon': 'notebook',
          'content': {
            'type': 'scroll_column',
            'children': [
              {
                'type': 'row',
                'children': [
                  {
                    'type': 'stat_card',
                    'label': 'Total Completed',
                    'expression':
                        'count(where(status, ==, Completed))',
                    'filter': [
                      {'field': 'schemaKey', 'op': '==', 'value': 'workout'},
                    ],
                  },
                  {
                    'type': 'stat_card',
                    'label': 'This Month',
                    'expression':
                        'count(where(status, ==, Completed), period(month))',
                    'filter': [
                      {'field': 'schemaKey', 'op': '==', 'value': 'workout'},
                    ],
                  },
                ],
              },
              {
                'type': 'section',
                'title': 'Workout Log',
                'children': [
                  {
                    'type': 'entry_list',
                    'filter': [
                      {'field': 'schemaKey', 'op': '==', 'value': 'workout'},
                      {'field': 'status', 'op': '==', 'value': 'Completed'},
                    ],
                    'query': {'orderBy': 'date', 'direction': 'desc'},
                    'itemLayout': {
                      'type': 'entry_card',
                      'title': '{{name}}',
                      'subtitle': '{{feeling}}',
                      'trailing': '{{rating}}',
                      'trailingFormat': 'rating',
                      'onTap': {
                        'type': 'navigate',
                        'screen': 'edit_workout',
                        'forwardFields': [
                          'name',
                          'type',
                          'date',
                          'status',
                          'exercises',
                          'duration',
                          'distance',
                          'feeling',
                          'rating',
                          'journal',
                        ],
                        'params': {'_schemaKey': 'workout'},
                      },
                      'swipeActions': {
                        'right': {
                          'type': 'delete_entry',
                          'confirm': true,
                          'confirmMessage': 'Delete this workout log?',
                        },
                      },
                    },
                  },
                ],
              },
            ],
          },
        },

        // ────────────── Tab 3: Goals ──────────────
        {
          'label': 'Goals',
          'icon': 'target',
          'content': {
            'type': 'scroll_column',
            'children': [
              {
                'type': 'row',
                'children': [
                  {
                    'type': 'stat_card',
                    'label': 'Active Goals',
                    'expression':
                        'count(where(status, ==, Active))',
                    'filter': [
                      {'field': 'schemaKey', 'op': '==', 'value': 'goal'},
                    ],
                  },
                ],
              },
              {
                'type': 'button',
                'label': 'Add Goal',
                'style': 'outlined',
                'action': {
                  'type': 'navigate',
                  'screen': 'add_goal',
                  'params': {'_schemaKey': 'goal'},
                },
              },
              {
                'type': 'section',
                'title': 'Active',
                'children': [
                  {
                    'type': 'entry_list',
                    'filter': [
                      {'field': 'schemaKey', 'op': '==', 'value': 'goal'},
                      {'field': 'status', 'op': '==', 'value': 'Active'},
                    ],
                    'query': {'orderBy': 'name', 'direction': 'asc'},
                    'itemLayout': {
                      'type': 'entry_card',
                      'title': '{{name}}',
                      'subtitle': '{{target}}',
                      'trailing': '{{targetDate}}',
                      'onTap': {
                        'type': 'navigate',
                        'screen': 'edit_goal',
                        'forwardFields': [
                          'name',
                          'type',
                          'targetDate',
                          'target',
                          'status',
                          'notes',
                        ],
                        'params': {'_schemaKey': 'goal'},
                      },
                      'swipeActions': {
                        'right': {
                          'type': 'delete_entry',
                          'confirm': true,
                          'confirmMessage': 'Delete this goal?',
                        },
                      },
                    },
                  },
                ],
              },
              {
                'type': 'section',
                'title': 'Achieved',
                'children': [
                  {
                    'type': 'entry_list',
                    'filter': [
                      {'field': 'schemaKey', 'op': '==', 'value': 'goal'},
                      {'field': 'status', 'op': '==', 'value': 'Achieved'},
                    ],
                    'query': {'orderBy': 'name', 'direction': 'asc'},
                    'itemLayout': {
                      'type': 'entry_card',
                      'title': '{{name}}',
                      'subtitle': '{{target}}',
                      'trailing': '{{targetDate}}',
                      'onTap': {
                        'type': 'navigate',
                        'screen': 'edit_goal',
                        'forwardFields': [
                          'name',
                          'type',
                          'targetDate',
                          'target',
                          'status',
                          'notes',
                        ],
                        'params': {'_schemaKey': 'goal'},
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
        'action': {
          'type': 'navigate',
          'screen': 'add_workout',
          'params': {'_schemaKey': 'workout'},
        },
      },
    },

    // ═══════════════════════════════════════════
    //  CALENDAR
    // ═══════════════════════════════════════════
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
            'filter': [
              {'field': 'schemaKey', 'op': '==', 'value': 'workout'},
            ],
            'onEntryTap': {'screen': 'edit_workout'},
            'forwardFields': [
              'name',
              'type',
              'date',
              'status',
              'exercises',
              'duration',
              'distance',
              'feeling',
              'rating',
              'journal',
            ],
          },
        ],
      },
    },

    // ═══════════════════════════════════════════
    //  FORMS
    // ═══════════════════════════════════════════
    'add_workout': {
      'id': 'add_workout',
      'type': 'form_screen',
      'title': 'New Workout',
      'submitLabel': 'Save',
      'defaults': {'status': 'Planned'},
      'children': [
        {'type': 'enum_selector', 'fieldKey': 'status'},
        {'type': 'text_input', 'fieldKey': 'name'},
        {'type': 'enum_selector', 'fieldKey': 'type'},
        {'type': 'date_picker', 'fieldKey': 'date'},
        {'type': 'text_input', 'fieldKey': 'exercises', 'multiline': true},
        {
          'type': 'conditional',
          'condition': {'field': 'status', 'op': '==', 'value': 'Completed'},
          'then': [
            {
              'type': 'section',
              'title': 'How did it go?',
              'children': [
                {'type': 'duration_picker', 'fieldKey': 'duration'},
                {
                  'type': 'conditional',
                  'condition': {'field': 'type', 'op': '==', 'value': 'Cardio'},
                  'then': [
                    {'type': 'number_input', 'fieldKey': 'distance'},
                  ],
                },
                {'type': 'enum_selector', 'fieldKey': 'feeling'},
                {'type': 'rating_input', 'fieldKey': 'rating'},
                {'type': 'text_input', 'fieldKey': 'journal', 'multiline': true},
              ],
            },
          ],
        },
      ],
    },
    'edit_workout': {
      'id': 'edit_workout',
      'type': 'form_screen',
      'title': 'Edit Workout',
      'editLabel': 'Update',
      'children': [
        {'type': 'enum_selector', 'fieldKey': 'status'},
        {'type': 'text_input', 'fieldKey': 'name'},
        {'type': 'enum_selector', 'fieldKey': 'type'},
        {'type': 'date_picker', 'fieldKey': 'date'},
        {'type': 'text_input', 'fieldKey': 'exercises', 'multiline': true},
        {
          'type': 'conditional',
          'condition': {'field': 'status', 'op': '==', 'value': 'Completed'},
          'then': [
            {
              'type': 'section',
              'title': 'How did it go?',
              'children': [
                {'type': 'duration_picker', 'fieldKey': 'duration'},
                {
                  'type': 'conditional',
                  'condition': {'field': 'type', 'op': '==', 'value': 'Cardio'},
                  'then': [
                    {'type': 'number_input', 'fieldKey': 'distance'},
                  ],
                },
                {'type': 'enum_selector', 'fieldKey': 'feeling'},
                {'type': 'rating_input', 'fieldKey': 'rating'},
                {'type': 'text_input', 'fieldKey': 'journal', 'multiline': true},
              ],
            },
          ],
        },
      ],
    },
    'add_goal': {
      'id': 'add_goal',
      'type': 'form_screen',
      'title': 'New Goal',
      'submitLabel': 'Save',
      'defaults': {'status': 'Active'},
      'children': [
        {'type': 'text_input', 'fieldKey': 'name'},
        {'type': 'enum_selector', 'fieldKey': 'type'},
        {'type': 'date_picker', 'fieldKey': 'targetDate'},
        {'type': 'text_input', 'fieldKey': 'target'},
        {'type': 'text_input', 'fieldKey': 'notes', 'multiline': true},
      ],
    },
    'edit_goal': {
      'id': 'edit_goal',
      'type': 'form_screen',
      'title': 'Edit Goal',
      'editLabel': 'Update',
      'children': [
        {'type': 'text_input', 'fieldKey': 'name'},
        {'type': 'enum_selector', 'fieldKey': 'type'},
        {'type': 'enum_selector', 'fieldKey': 'status'},
        {'type': 'date_picker', 'fieldKey': 'targetDate'},
        {'type': 'text_input', 'fieldKey': 'target'},
        {'type': 'text_input', 'fieldKey': 'notes', 'multiline': true},
      ],
    },
  },
};
