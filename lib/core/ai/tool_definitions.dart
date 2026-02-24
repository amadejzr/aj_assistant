const toolsRequiringApproval = {
  'createEntry',
  'createEntries',
  'updateEntry',
  'updateEntries',
  'createModule',
};

const toolDefinitions = <Map<String, dynamic>>[
  {
    'name': 'createEntry',
    'description':
        'Create a new data entry in a module. Use this when the user wants '
            'to add, log, or record something (an expense, a workout, a habit '
            'check-in, etc.). Always confirm the module and data before creating.',
    'input_schema': {
      'type': 'object',
      'properties': {
        'moduleId': {
          'type': 'string',
          'description': 'The ID of the module to create the entry in.',
        },
        'schemaKey': {
          'type': 'string',
          'description':
              'The schema key within the module (e.g. "default", '
                  '"transactions", "accounts"). Use "default" if the module '
                  'has only one schema.',
        },
        'data': {
          'type': 'object',
          'description':
              'The entry data as key-value pairs matching the schema field keys.',
        },
      },
      'required': ['moduleId', 'schemaKey', 'data'],
    },
  },
  {
    'name': 'createEntries',
    'description':
        'Create multiple entries in a module at once. Use this instead of '
            'createEntry when the user wants to add several items in one go. '
            'All entries use the same schema. Maximum 50 entries per call.',
    'input_schema': {
      'type': 'object',
      'properties': {
        'moduleId': {
          'type': 'string',
          'description': 'The ID of the module to create the entries in.',
        },
        'schemaKey': {
          'type': 'string',
          'description': 'The schema key within the module.',
        },
        'entries': {
          'type': 'array',
          'description': 'Array of entries to create.',
          'items': {
            'type': 'object',
            'properties': {
              'data': {
                'type': 'object',
                'description': 'The entry data as key-value pairs.',
              },
            },
            'required': ['data'],
          },
        },
      },
      'required': ['moduleId', 'schemaKey', 'entries'],
    },
  },
  {
    'name': 'queryEntries',
    'description':
        'Query and read entries from a module. Use this to look up, search, '
            'list, or check existing data. Returns entries matching the filters.',
    'input_schema': {
      'type': 'object',
      'properties': {
        'moduleId': {
          'type': 'string',
          'description': 'The ID of the module to query.',
        },
        'schemaKey': {
          'type': 'string',
          'description': 'Optional schema key to filter by.',
        },
        'filters': {
          'type': 'array',
          'description': 'Optional filters to narrow results.',
          'items': {
            'type': 'object',
            'properties': {
              'field': {'type': 'string', 'description': 'The data field key.'},
              'op': {
                'type': 'string',
                'enum': ['==', '!=', '>', '<', '>=', '<='],
                'description': 'Comparison operator.',
              },
              'value': {'description': 'The value to compare against.'},
            },
            'required': ['field', 'op', 'value'],
          },
        },
        'orderBy': {
          'type': 'string',
          'description':
              'Field key to order results by. Defaults to created_at.',
        },
        'limit': {
          'type': 'number',
          'description': 'Max entries to return (default 20, max 50).',
        },
      },
      'required': ['moduleId'],
    },
  },
  {
    'name': 'updateEntry',
    'description':
        'Update an existing entry in a module. Performs a partial merge — '
            'only the provided fields are changed.',
    'input_schema': {
      'type': 'object',
      'properties': {
        'moduleId': {
          'type': 'string',
          'description': 'The ID of the module containing the entry.',
        },
        'entryId': {
          'type': 'string',
          'description': 'The ID of the entry to update.',
        },
        'data': {
          'type': 'object',
          'description': 'The fields to update as key-value pairs.',
        },
      },
      'required': ['moduleId', 'entryId', 'data'],
    },
  },
  {
    'name': 'updateEntries',
    'description':
        'Update multiple existing entries in a module at once. '
            'Each entry can have different fields updated. Maximum 50 per call.',
    'input_schema': {
      'type': 'object',
      'properties': {
        'moduleId': {
          'type': 'string',
          'description': 'The ID of the module containing the entries.',
        },
        'entries': {
          'type': 'array',
          'description': 'Array of entries to update.',
          'items': {
            'type': 'object',
            'properties': {
              'entryId': {
                'type': 'string',
                'description': 'The ID of the entry to update.',
              },
              'data': {
                'type': 'object',
                'description': 'The fields to update as key-value pairs.',
              },
            },
            'required': ['entryId', 'data'],
          },
        },
      },
      'required': ['moduleId', 'entries'],
    },
  },
  {
    'name': 'getModuleSummary',
    'description':
        'Get an overview of a module\'s data without fetching every entry. '
            'Returns entry counts, recent entries, and numeric field aggregates.',
    'input_schema': {
      'type': 'object',
      'properties': {
        'moduleId': {
          'type': 'string',
          'description': 'The ID of the module to summarize.',
        },
        'schemaKey': {
          'type': 'string',
          'description': 'Optional schema key to narrow the summary.',
        },
      },
      'required': ['moduleId'],
    },
  },
  {
    'name': 'createModule',
    'description':
        'Create a new module with database tables and blueprint screens. '
            'See the BLUEPRINT REFERENCE section in your system prompt for '
            'exact widget specs. Follow those specs precisely.\n\n'
            'DATABASE RULES:\n'
            '- Table names: m_{snake_module_name}_{schema_key}\n'
            '- All CREATE statements MUST use IF NOT EXISTS\n'
            '- Every table MUST have: id TEXT PRIMARY KEY, '
            'created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL\n\n'
            'SCREEN RULES:\n'
            '- Every module needs a "main" screen\n'
            '- Root screen type must be "screen", "form_screen", or '
            '"tab_screen"\n'
            '- All input widgets use "fieldKey" (NOT "key") to bind to '
            'database columns\n'
            '- Use {{fieldName}} templates in entry_card title/subtitle/trailing\n'
            '- form_screen needs an "add_" prefixed screen ID to create entries\n\n'
            'DATA ACCESS (CRITICAL — screens will NOT work without this):\n'
            '- Every screen that DISPLAYS data needs a "queries" map with SQL SELECT statements\n'
            '- Every form_screen that SAVES data needs a "mutations" map with create/update/delete SQL\n'
            '- The main screen should also have mutations if it has swipe-to-delete or inline updates\n'
            '- See BLUEPRINT REFERENCE in system prompt for exact format and examples',
    'input_schema': {
      'type': 'object',
      'properties': {
        'name': {
          'type': 'string',
          'description': 'Display name for the module.',
        },
        'description': {
          'type': 'string',
          'description': 'Short description of what the module tracks.',
        },
        'icon': {
          'type': 'string',
          'description':
              'Phosphor icon name (e.g. "wallet", "barbell", "check-circle").',
        },
        'color': {
          'type': 'string',
          'description': 'Hex color for the module accent, e.g. "#D94E33".',
        },
        'database': {
          'type': 'object',
          'description': 'Database schema definition.',
          'properties': {
            'tableNames': {
              'type': 'object',
              'description':
                  'Map of schema key → SQLite table name. '
                      'e.g. { "default": "m_water_log_default" } for '
                      'single-table, or { "account": "m_budget_accounts", '
                      '"expense": "m_budget_expenses" } for multi-table.',
            },
            'setup': {
              'type': 'array',
              'items': {'type': 'string'},
              'description':
                  'CREATE TABLE IF NOT EXISTS and CREATE INDEX IF NOT EXISTS '
                      'statements, executed in order.',
            },
            'teardown': {
              'type': 'array',
              'items': {'type': 'string'},
              'description':
                  'DROP TABLE IF EXISTS statements, one per table.',
            },
          },
          'required': ['tableNames', 'setup', 'teardown'],
        },
        'screens': {
          'type': 'object',
          'description':
              'Map of screen ID → blueprint JSON. Must include "main". '
                  'Add screens use "add_entry" or "add_{schemaKey}" IDs. '
                  'Each screen is a JSON object with "type" as root widget. '
                  'See BLUEPRINT REFERENCE for exact widget specs.',
          'additionalProperties': {
            'type': 'object',
            'description': 'A blueprint screen definition.',
            'properties': {
              'type': {
                'type': 'string',
                'enum': ['screen', 'form_screen', 'tab_screen'],
                'description': 'Root widget type for this screen.',
              },
              'title': {
                'type': 'string',
                'description': 'Screen title shown in the app bar.',
              },
              'children': {
                'type': 'array',
                'description':
                    'Child widgets. For screen/form_screen, array of widget '
                        'objects. Each widget has "type" and type-specific fields.',
              },
              'fab': {
                'type': 'object',
                'description':
                    'Floating action button. '
                        '{ "type": "fab", "icon": "plus", '
                        '"action": { "type": "navigate", "screen": "add_entry" } }',
              },
              'submitLabel': {
                'type': 'string',
                'description': 'form_screen only. Button label, default "Save".',
              },
              'defaults': {
                'type': 'object',
                'description':
                    'form_screen only. Default field values for new entries.',
              },
              'tabs': {
                'type': 'array',
                'description':
                    'tab_screen only. Array of { label, icon, content } '
                        'where content is a widget tree (usually scroll_column).',
              },
              'queries': {
                'type': 'object',
                'description':
                    'REQUIRED for screens that display data. Map of query name '
                        '→ { "sql": "SELECT ..." }. Example: '
                        '{ "entries": { "sql": "SELECT id, name, amount FROM '
                        '"m_expenses_default" ORDER BY created_at DESC" } }. '
                        'Always quote table names with double quotes in SQL.',
              },
              'mutations': {
                'type': 'object',
                'description':
                    'REQUIRED for form screens that save data. '
                        '{ "create": "INSERT INTO ...", '
                        '"update": "UPDATE ... WHERE id = :id", '
                        '"delete": "DELETE FROM ... WHERE id = :id" }. '
                        'Use :paramName for named params. :id, :created_at, '
                        ':updated_at are auto-generated. Use COALESCE(:field, field) '
                        'in UPDATE for partial updates.',
              },
            },
            'required': ['type'],
          },
        },
        'navigation': {
          'type': 'object',
          'description':
              'Optional. For multi-screen modules with bottom navigation.\n'
                  'Format: { "bottomNav": { "items": [ '
                  '{ "label": "Home", "icon": "house", "screenId": "main" }, '
                  '{ "label": "Stats", "icon": "chart-bar", "screenId": "stats" } '
                  '] } }',
          'properties': {
            'bottomNav': {
              'type': 'object',
              'properties': {
                'items': {
                  'type': 'array',
                  'items': {
                    'type': 'object',
                    'properties': {
                      'label': {'type': 'string'},
                      'icon': {'type': 'string'},
                      'screenId': {'type': 'string'},
                    },
                    'required': ['label', 'icon', 'screenId'],
                  },
                },
              },
            },
          },
        },
        'guide': {
          'type': 'array',
          'description':
              'Optional onboarding guide. Array of { title, body } objects.',
          'items': {
            'type': 'object',
            'properties': {
              'title': {'type': 'string'},
              'body': {'type': 'string'},
            },
          },
        },
      },
      'required': ['name', 'description', 'database', 'screens'],
    },
  },
];

String describeAction(String name, Map<String, dynamic> input) {
  switch (name) {
    case 'createEntry':
      final data = input['data'] as Map? ?? {};
      final fields = data.entries.map((e) => '${e.key}: ${e.value}').join(', ');
      return 'Create entry in "${input['schemaKey']}": $fields';
    case 'createEntries':
      final entries = input['entries'] as List? ?? [];
      return 'Create ${entries.length} entries in "${input['schemaKey']}"';
    case 'updateEntry':
      final data = input['data'] as Map? ?? {};
      final fields = data.entries.map((e) => '${e.key}: ${e.value}').join(', ');
      return 'Update entry ${input['entryId']}: $fields';
    case 'updateEntries':
      final entries = input['entries'] as List? ?? [];
      return 'Update ${entries.length} entries in module';
    case 'createModule':
      final name = input['name'] as String? ?? 'Unknown';
      final db = input['database'] as Map? ?? {};
      final setup = db['setup'] as List? ?? [];
      final tableCount =
          setup.where((s) => (s as String).toUpperCase().startsWith('CREATE TABLE')).length;
      final screens = input['screens'] as Map? ?? {};
      return 'Create module "$name" ($tableCount table${tableCount == 1 ? '' : 's'}, '
          '${screens.length} screen${screens.length == 1 ? '' : 's'})';
    default:
      return '$name($input)';
  }
}
