const toolsRequiringApproval = {
  'createEntry',
  'createEntries',
  'updateEntry',
  'updateEntries',
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
    default:
      return '$name($input)';
  }
}
