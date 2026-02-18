const mealsTemplate = {
  'name': 'Meal Planner',
  'description': 'Plan your meals, eat well, repeat',
  'longDescription':
      'Plan your breakfast, lunch, dinner, and snacks for the week ahead. '
      'Mark meals as eaten and rate them. Jot down ingredients and prep notes '
      'for easy reference. Ask the AI to generate a full week of meals for '
      'any diet.',
  'icon': 'restaurant',
  'color': '#43A047',
  'category': 'Lifestyle',
  'tags': ['meals', 'food', 'cooking', 'diet', 'nutrition', 'weekly', 'planning'],
  'featured': false,
  'sortOrder': 3,
  'installCount': 0,
  'version': 1,
  'settings': {},
  'guide': [
    {
      'title': 'Plan Your Week',
      'body':
          'Add meals with a date and type (Breakfast, Lunch, Dinner, Snack). '
          'Or ask the AI: "plan me healthy meals for next week."',
    },
    {
      'title': 'Eat & Log',
      'body':
          'Switch a meal\'s status to "Eaten" to unlock the rating and notes '
          'fields. Quick reflection while it\'s fresh.',
    },
    {
      'title': 'Ingredients & Prep',
      'body':
          'Use the ingredients field as a shopping checklist and prep notes '
          'for quick recipes or cooking tips.',
    },
    {
      'title': 'AI Suggestions',
      'body':
          'Ask the AI for meal ideas, themed weeks, or diet-specific plans. '
          'It creates all the entries for you.',
    },
  ],

  // ─── Schemas ───
  'schemas': {
    'default': {
      'label': 'Meal',
      'icon': 'restaurant',
      'fields': {
        'name': {
          'key': 'name',
          'type': 'text',
          'label': 'Meal',
          'required': true,
        },
        'mealType': {
          'key': 'mealType',
          'type': 'enumType',
          'label': 'Type',
          'options': ['Breakfast', 'Lunch', 'Dinner', 'Snack'],
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
          'options': ['Planned', 'Eaten', 'Skipped'],
        },
        'ingredients': {
          'key': 'ingredients',
          'type': 'text',
          'label': 'Ingredients',
        },
        'prep': {
          'key': 'prep',
          'type': 'text',
          'label': 'Prep Notes',
        },
        'rating': {
          'key': 'rating',
          'type': 'rating',
          'label': 'Rating',
          'constraints': {'min': 1, 'max': 5},
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
    'main': {
      'id': 'main',
      'type': 'tab_screen',
      'title': 'Meal Planner',
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
                  },
                  {
                    'type': 'stat_card',
                    'label': 'Eaten This Week',
                    'expression':
                        'count(where(status, ==, Eaten), period(week))',
                  },
                ],
              },
              {
                'type': 'section',
                'title': 'Upcoming Meals',
                'children': [
                  {
                    'type': 'entry_list',
                    'filter': [
                      {'field': 'status', 'op': '==', 'value': 'Planned'},
                    ],
                    'query': {'orderBy': 'date', 'direction': 'asc'},
                    'itemLayout': {
                      'type': 'entry_card',
                      'title': '{{name}}',
                      'subtitle': '{{date}}',
                      'trailing': '{{mealType}}',
                      'onTap': {
                        'type': 'navigate',
                        'screen': 'edit_entry',
                        'forwardFields': [
                          'name',
                          'mealType',
                          'date',
                          'status',
                          'ingredients',
                          'prep',
                          'rating',
                          'notes',
                        ],
                      },
                      'swipeActions': {
                        'right': {
                          'type': 'delete_entry',
                          'confirm': true,
                          'confirmMessage': 'Remove this meal?',
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
          'icon': 'check_circle',
          'content': {
            'type': 'scroll_column',
            'children': [
              {
                'type': 'row',
                'children': [
                  {
                    'type': 'stat_card',
                    'label': 'Total Eaten',
                    'expression': 'count(where(status, ==, Eaten))',
                  },
                  {
                    'type': 'stat_card',
                    'label': 'This Month',
                    'expression':
                        'count(where(status, ==, Eaten), period(month))',
                  },
                ],
              },
              {
                'type': 'section',
                'title': 'Meal Log',
                'children': [
                  {
                    'type': 'entry_list',
                    'filter': [
                      {'field': 'status', 'op': '==', 'value': 'Eaten'},
                    ],
                    'query': {'orderBy': 'date', 'direction': 'desc'},
                    'itemLayout': {
                      'type': 'entry_card',
                      'title': '{{name}}',
                      'subtitle': '{{mealType}}',
                      'trailing': '{{rating}}',
                      'trailingFormat': 'rating',
                      'onTap': {
                        'type': 'navigate',
                        'screen': 'edit_entry',
                        'forwardFields': [
                          'name',
                          'mealType',
                          'date',
                          'status',
                          'ingredients',
                          'prep',
                          'rating',
                          'notes',
                        ],
                      },
                      'swipeActions': {
                        'right': {
                          'type': 'delete_entry',
                          'confirm': true,
                          'confirmMessage': 'Delete this meal log?',
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

    // ─── Calendar ───
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
            'onEntryTap': {'screen': 'edit_entry'},
            'forwardFields': [
              'name',
              'mealType',
              'date',
              'status',
              'ingredients',
              'prep',
              'rating',
              'notes',
            ],
          },
        ],
      },
    },

    // ─── Add entry ───
    'add_entry': {
      'id': 'add_entry',
      'type': 'form_screen',
      'title': 'New Meal',
      'submitLabel': 'Save',
      'defaults': {'status': 'Planned'},
      'children': [
        {'type': 'enum_selector', 'fieldKey': 'status'},
        {'type': 'text_input', 'fieldKey': 'name'},
        {'type': 'enum_selector', 'fieldKey': 'mealType'},
        {'type': 'date_picker', 'fieldKey': 'date'},
        {'type': 'text_input', 'fieldKey': 'ingredients', 'multiline': true},
        {'type': 'text_input', 'fieldKey': 'prep', 'multiline': true},
        {
          'type': 'conditional',
          'condition': {'field': 'status', 'op': '==', 'value': 'Eaten'},
          'then': [
            {
              'type': 'section',
              'title': 'How was it?',
              'children': [
                {'type': 'rating_input', 'fieldKey': 'rating'},
                {'type': 'text_input', 'fieldKey': 'notes', 'multiline': true},
              ],
            },
          ],
        },
      ],
    },

    // ─── Edit entry ───
    'edit_entry': {
      'id': 'edit_entry',
      'type': 'form_screen',
      'title': 'Edit Meal',
      'editLabel': 'Update',
      'children': [
        {'type': 'enum_selector', 'fieldKey': 'status'},
        {'type': 'text_input', 'fieldKey': 'name'},
        {'type': 'enum_selector', 'fieldKey': 'mealType'},
        {'type': 'date_picker', 'fieldKey': 'date'},
        {'type': 'text_input', 'fieldKey': 'ingredients', 'multiline': true},
        {'type': 'text_input', 'fieldKey': 'prep', 'multiline': true},
        {
          'type': 'conditional',
          'condition': {'field': 'status', 'op': '==', 'value': 'Eaten'},
          'then': [
            {
              'type': 'section',
              'title': 'How was it?',
              'children': [
                {'type': 'rating_input', 'fieldKey': 'rating'},
                {'type': 'text_input', 'fieldKey': 'notes', 'multiline': true},
              ],
            },
          ],
        },
      ],
    },
  },
};
