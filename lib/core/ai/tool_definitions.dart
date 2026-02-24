import 'prompts/blueprint_reference.dart';

const toolsRequiringApproval = {
  'createEntry',
  'createEntries',
  'updateEntry',
  'updateEntries',
  'createModule',
};

/// Returns the tool definitions appropriate for the current context.
///
/// [includeModuleCreation] controls whether the `createModule` tool (with its
/// large blueprint reference) is included. Pass `false` when the user already
/// has modules and the message doesn't suggest creating one — this saves
/// significant tokens per API call.
List<Map<String, dynamic>> getToolDefinitions({
  bool includeModuleCreation = true,
}) {
  return [
    ...coreToolDefinitions,
    if (includeModuleCreation) createModuleToolDefinition,
  ];
}

/// All tools that are always included regardless of context.
final coreToolDefinitions = <Map<String, dynamic>>[
  {
    'name': 'createEntry',
    'description':
        'Create a new data entry in a module. Use this when the user wants '
            'to add, log, or record something (an expense, a workout, a habit '
            'check-in, etc.). Call this tool directly — the app shows the user '
            'an approval card before anything is saved. Do NOT include id, '
            'created_at, or updated_at in data — they are auto-generated.',
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
            'All entries use the same schema. Maximum 50 entries per call. '
            'Do NOT include id, created_at, or updated_at — they are auto-generated.',
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
        'Query and read entries from a module. Best for simple lookups: '
            'list recent entries, find by field value, check if something exists. '
            'For statistics, aggregations, GROUP BY, or date ranges use runQuery instead.',
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
        'orderDirection': {
          'type': 'string',
          'enum': ['ASC', 'DESC'],
          'description': 'Sort direction. Defaults to DESC (newest first).',
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
            'Returns column schema (names and types), entry count, and the 5 '
            'most recent entries. Use this to understand a module\'s structure '
            'before querying or to display a quick summary.',
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
    'name': 'runQuery',
    'description':
        'Run a custom read-only SQL SELECT query against a module\'s table. '
            'Use this for statistics, aggregations, date ranges, GROUP BY, '
            'text search (LIKE), JOINs, and anything queryEntries can\'t do. '
            'Prefer this over queryEntries for any analytical question.\n\n'
            'The placeholder {{table}} is replaced with the actual table name.\n\n'
            'Examples:\n'
            '- Total spent: SELECT SUM(amount) as total FROM {{table}}\n'
            '- This month: SELECT SUM(amount) as total FROM {{table}} '
            'WHERE date >= strftime(\'%s\', date(\'now\',\'start of month\')) * 1000\n'
            '- By category: SELECT category, SUM(amount) as total FROM '
            '{{table}} GROUP BY category ORDER BY total DESC\n'
            '- Count: SELECT COUNT(*) as count FROM {{table}} WHERE completed = 1',
    'input_schema': {
      'type': 'object',
      'properties': {
        'moduleId': {
          'type': 'string',
          'description': 'The ID of the module to query.',
        },
        'schemaKey': {
          'type': 'string',
          'description':
              'Schema key within the module (default: "default").',
        },
        'sql': {
          'type': 'string',
          'description':
              'A SELECT query using {{table}} as the table placeholder. '
                  'Only SELECT is allowed.',
        },
      },
      'required': ['moduleId', 'sql'],
    },
  },
];

/// The createModule tool with full blueprint reference.
/// Separated because the blueprint reference is ~4k tokens — only include
/// when module creation is relevant.
final createModuleToolDefinition = <String, dynamic>{
  'name': 'createModule',
  'description':
      'Create a new module with database tables and blueprint screens. '
          'Follow the BLUEPRINT REFERENCE below precisely.\n\n'
          '$blueprintReference',
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
        'tables': {
          'type': 'object',
          'description':
              'Map of schema key → table definition. '
                  'e.g. { "default": { "columns": [...] } } for single-table, '
                  'or { "expenses": { "columns": [...] }, "categories": { "columns": [...] } } '
                  'for multi-table. CREATE TABLE, DROP TABLE, and mutations '
                  'are auto-generated.',
          'additionalProperties': {
            'type': 'object',
            'properties': {
              'columns': {
                'type': 'array',
                'description': 'Column definitions for this table.',
                'items': {
                  'type': 'object',
                  'properties': {
                    'name': {
                      'type': 'string',
                      'description': 'Column name (snake_case).',
                    },
                    'type': {
                      'type': 'string',
                      'enum': [
                        'text', 'number', 'boolean', 'datetime',
                        'enumType', 'multiEnum', 'currency', 'rating',
                        'reference', 'duration', 'url', 'phone', 'email',
                      ],
                      'description': 'Column type.',
                    },
                    'required': {
                      'type': 'boolean',
                      'description': 'Whether the column is NOT NULL.',
                    },
                  },
                  'required': ['name', 'type'],
                },
              },
            },
            'required': ['columns'],
          },
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
              'table': {
                'type': 'string',
                'description':
                    'form_screen only. Schema key of the table this form '
                        'targets (e.g. "default", "expenses"). Mutations are '
                        'auto-generated from this.',
              },
              'queries': {
                'type': 'object',
                'description':
                    'REQUIRED for screens that display data. Map of query name '
                        '→ { "sql": "SELECT ..." }. Use {{schemaKey}} '
                        'placeholders for table names — they are auto-resolved. '
                        'Example: { "entries": { "sql": "SELECT id, name '
                        'FROM {{default}} ORDER BY created_at DESC" } }.',
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
      'required': ['name', 'description', 'tables', 'screens'],
    },
  };

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
      final tables = input['tables'] as Map? ?? {};
      final screens = input['screens'] as Map? ?? {};
      return 'Create module "$name" (${tables.length} table${tables.length == 1 ? '' : 's'}, '
          '${screens.length} screen${screens.length == 1 ? '' : 's'})';
    default:
      return '$name($input)';
  }
}
