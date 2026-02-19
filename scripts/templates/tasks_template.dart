const tasksTemplate = {
  'name': 'Tasks',
  'description': 'Manage tasks with priorities & due dates',
  'longDescription':
      'A focused task manager to capture what you need to do, set priorities, '
      'and track progress. Organize tasks by project, see what\'s overdue or '
      'due today at a glance, and move items through todo → in progress → done. '
      'Includes a calendar view for deadline planning.',
  'icon': 'checklist',
  'color': '#D4763A',
  'category': 'Productivity',
  'tags': ['tasks', 'todo', 'productivity', 'projects'],
  'featured': false,
  'sortOrder': 2,
  'installCount': 0,
  'version': 1,
  'settings': {},
  'guide': [
    {
      'title': 'Capture Tasks',
      'body':
          'Tap + to add a task. Give it a title, set a priority, and optionally '
          'pick a due date and project. Tasks default to "todo" status.',
    },
    {
      'title': 'Work Through Your List',
      'body':
          'Move tasks to "in progress" when you start working on them, and '
          '"done" when finished. The Active tab shows everything that still '
          'needs attention, sorted by priority.',
    },
    {
      'title': 'Stay on Top of Deadlines',
      'body':
          'The stat cards show overdue and due-today counts so nothing slips. '
          'Use the calendar view to plan your week ahead.',
    },
  ],

  // ─── Schemas ───
  'schemas': {
    'default': {
      'label': 'Task',
      'icon': 'checklist',
      'fields': {
        'title': {
          'key': 'title',
          'type': 'text',
          'label': 'Title',
          'required': true,
        },
        'description': {
          'key': 'description',
          'type': 'text',
          'label': 'Description',
        },
        'priority': {
          'key': 'priority',
          'type': 'enumType',
          'label': 'Priority',
          'required': true,
          'options': ['high', 'medium', 'low'],
        },
        'status': {
          'key': 'status',
          'type': 'enumType',
          'label': 'Status',
          'required': true,
          'options': ['todo', 'in_progress', 'done'],
        },
        'due_date': {
          'key': 'due_date',
          'type': 'datetime',
          'label': 'Due Date',
        },
        'project': {
          'key': 'project',
          'type': 'enumType',
          'label': 'Project',
          'options': ['personal', 'work', 'errands', 'learning'],
        },
      },
    },
  },

  // ─── Screens ───
  'screens': {
    'main': {
      'id': 'main',
      'type': 'tab_screen',
      'title': 'Tasks',
      'tabs': [
        // ────────────── Tab 1: Active ──────────────
        {
          'label': 'Active',
          'icon': 'pending_actions',
          'content': {
            'type': 'scroll_column',
            'children': [
              {
                'type': 'row',
                'children': [
                  {
                    'type': 'stat_card',
                    'label': 'Overdue',
                    'expression':
                        'count(where(status, !=, done), where(due_date, <, today))',
                  },
                  {
                    'type': 'stat_card',
                    'label': 'Due Today',
                    'expression':
                        'count(where(status, !=, done), where(due_date, ==, today))',
                  },
                  {
                    'type': 'stat_card',
                    'label': 'Open',
                    'expression': 'count(where(status, !=, done))',
                  },
                ],
              },
              {
                'type': 'button',
                'label': 'View Calendar',
                'style': 'outlined',
                'action': {'type': 'navigate', 'screen': 'calendar'},
              },
              {
                'type': 'section',
                'title': 'High Priority',
                'children': [
                  {
                    'type': 'entry_list',
                    'filter': [
                      {'field': 'status', 'op': '!=', 'value': 'done'},
                      {'field': 'priority', 'op': '==', 'value': 'high'},
                    ],
                    'query': {'orderBy': 'due_date', 'direction': 'asc'},
                    'itemLayout': {
                      'type': 'entry_card',
                      'title': '{{title}}',
                      'subtitle': '{{project}}',
                      'trailing': '{{due_date}}',
                      'trailingFormat': 'relative_date',
                      'onTap': {
                        'type': 'navigate',
                        'screen': 'edit_entry',
                        'forwardFields': [
                          'title',
                          'description',
                          'priority',
                          'status',
                          'due_date',
                          'project',
                        ],
                      },
                      'swipeActions': {
                        'left': {
                          'type': 'update_entry',
                          'data': {'status': 'done'},
                          'label': 'Done',
                        },
                        'right': {
                          'type': 'delete_entry',
                          'confirm': true,
                          'confirmMessage': 'Delete this task?',
                        },
                      },
                    },
                  },
                ],
              },
              {
                'type': 'section',
                'title': 'Medium Priority',
                'children': [
                  {
                    'type': 'entry_list',
                    'filter': [
                      {'field': 'status', 'op': '!=', 'value': 'done'},
                      {'field': 'priority', 'op': '==', 'value': 'medium'},
                    ],
                    'query': {'orderBy': 'due_date', 'direction': 'asc'},
                    'itemLayout': {
                      'type': 'entry_card',
                      'title': '{{title}}',
                      'subtitle': '{{project}}',
                      'trailing': '{{due_date}}',
                      'trailingFormat': 'relative_date',
                      'onTap': {
                        'type': 'navigate',
                        'screen': 'edit_entry',
                        'forwardFields': [
                          'title',
                          'description',
                          'priority',
                          'status',
                          'due_date',
                          'project',
                        ],
                      },
                      'swipeActions': {
                        'left': {
                          'type': 'update_entry',
                          'data': {'status': 'done'},
                          'label': 'Done',
                        },
                        'right': {
                          'type': 'delete_entry',
                          'confirm': true,
                          'confirmMessage': 'Delete this task?',
                        },
                      },
                    },
                  },
                ],
              },
              {
                'type': 'section',
                'title': 'Low Priority',
                'children': [
                  {
                    'type': 'entry_list',
                    'filter': [
                      {'field': 'status', 'op': '!=', 'value': 'done'},
                      {'field': 'priority', 'op': '==', 'value': 'low'},
                    ],
                    'query': {'orderBy': 'due_date', 'direction': 'asc'},
                    'itemLayout': {
                      'type': 'entry_card',
                      'title': '{{title}}',
                      'subtitle': '{{project}}',
                      'trailing': '{{due_date}}',
                      'trailingFormat': 'relative_date',
                      'onTap': {
                        'type': 'navigate',
                        'screen': 'edit_entry',
                        'forwardFields': [
                          'title',
                          'description',
                          'priority',
                          'status',
                          'due_date',
                          'project',
                        ],
                      },
                      'swipeActions': {
                        'left': {
                          'type': 'update_entry',
                          'data': {'status': 'done'},
                          'label': 'Done',
                        },
                        'right': {
                          'type': 'delete_entry',
                          'confirm': true,
                          'confirmMessage': 'Delete this task?',
                        },
                      },
                    },
                  },
                ],
              },
            ],
          },
        },

        // ────────────── Tab 2: Done ──────────────
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
                    'expression': 'count(where(status, ==, done))',
                  },
                  {
                    'type': 'stat_card',
                    'label': 'This Week',
                    'expression':
                        'count(where(status, ==, done), period(week))',
                  },
                ],
              },
              {
                'type': 'section',
                'title': 'Completed Tasks',
                'children': [
                  {
                    'type': 'entry_list',
                    'filter': [
                      {'field': 'status', 'op': '==', 'value': 'done'},
                    ],
                    'query': {'orderBy': 'updatedAt', 'direction': 'desc'},
                    'itemLayout': {
                      'type': 'entry_card',
                      'title': '{{title}}',
                      'subtitle': '{{project}}',
                      'trailing': '{{priority}}',
                      'onTap': {
                        'type': 'navigate',
                        'screen': 'edit_entry',
                        'forwardFields': [
                          'title',
                          'description',
                          'priority',
                          'status',
                          'due_date',
                          'project',
                        ],
                      },
                      'swipeActions': {
                        'right': {
                          'type': 'delete_entry',
                          'confirm': true,
                          'confirmMessage': 'Delete this task?',
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
            'dateField': 'due_date',
            'onEntryTap': {'screen': 'edit_entry'},
            'forwardFields': [
              'title',
              'description',
              'priority',
              'status',
              'due_date',
              'project',
            ],
          },
        ],
      },
    },

    // ─── Add entry ───
    'add_entry': {
      'id': 'add_entry',
      'type': 'form_screen',
      'title': 'New Task',
      'submitLabel': 'Save',
      'defaults': {'status': 'todo', 'priority': 'medium'},
      'children': [
        {'type': 'text_input', 'fieldKey': 'title'},
        {
          'type': 'text_input',
          'fieldKey': 'description',
          'multiline': true,
        },
        {'type': 'enum_selector', 'fieldKey': 'priority'},
        {'type': 'enum_selector', 'fieldKey': 'status'},
        {'type': 'date_picker', 'fieldKey': 'due_date'},
        {'type': 'enum_selector', 'fieldKey': 'project'},
      ],
    },

    // ─── Edit entry ───
    'edit_entry': {
      'id': 'edit_entry',
      'type': 'form_screen',
      'title': 'Edit Task',
      'editLabel': 'Update',
      'children': [
        {'type': 'text_input', 'fieldKey': 'title'},
        {
          'type': 'text_input',
          'fieldKey': 'description',
          'multiline': true,
        },
        {'type': 'enum_selector', 'fieldKey': 'priority'},
        {'type': 'enum_selector', 'fieldKey': 'status'},
        {'type': 'date_picker', 'fieldKey': 'due_date'},
        {'type': 'enum_selector', 'fieldKey': 'project'},
      ],
    },
  },
};
