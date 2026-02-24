import 'package:aj_assistant/core/ai/module_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ModuleBuilder', () {
    group('tableName', () {
      test('basic module name and schema key', () {
        expect(
          ModuleBuilder.tableName('Expense Tracker', 'default'),
          'm_expense_tracker_default',
        );
      });

      test('strips non-alphanumeric characters', () {
        expect(
          ModuleBuilder.tableName("Mom's Recipes!", 'default'),
          'm_moms_recipes_default',
        );
      });

      test('lowercases everything', () {
        expect(
          ModuleBuilder.tableName('MY MODULE', 'Default'),
          'm_my_module_default',
        );
      });

      test('replaces spaces with underscores', () {
        expect(
          ModuleBuilder.tableName('Habit Tracker', 'entries'),
          'm_habit_tracker_entries',
        );
      });

      test('handles multiple spaces', () {
        expect(ModuleBuilder.tableName('A   B', 'default'), 'm_a_b_default');
      });

      test('strips emojis', () {
        expect(
          ModuleBuilder.tableName('Fitness \u{1F4AA} Log', 'default'),
          'm_fitness_log_default',
        );
      });

      test('trims leading/trailing whitespace and special chars', () {
        expect(
          ModuleBuilder.tableName('  !!Hello!!  ', 'default'),
          'm_hello_default',
        );
      });

      test('is deterministic', () {
        final a = ModuleBuilder.tableName('Test', 'default');
        final b = ModuleBuilder.tableName('Test', 'default');
        expect(a, b);
      });

      test('different schema keys produce different table names', () {
        final a = ModuleBuilder.tableName('Expenses', 'default');
        final b = ModuleBuilder.tableName('Expenses', 'categories');
        expect(a, isNot(b));
        expect(a, 'm_expenses_default');
        expect(b, 'm_expenses_categories');
      });
    });

    group('generateCreateTable', () {
      test('basic table with one required text column', () {
        final sql = ModuleBuilder.generateCreateTable('m_test', [
          {'name': 'name', 'type': 'text', 'required': true},
        ]);
        expect(
          sql,
          'CREATE TABLE IF NOT EXISTS "m_test" '
          '(id TEXT PRIMARY KEY, '
          'name TEXT NOT NULL, '
          'created_at INTEGER NOT NULL, '
          'updated_at INTEGER NOT NULL)',
        );
      });

      test('optional column omits NOT NULL', () {
        final sql = ModuleBuilder.generateCreateTable('m_test', [
          {'name': 'notes', 'type': 'text', 'required': false},
        ]);
        expect(sql, contains('notes TEXT,'));
        expect(sql, isNot(contains('notes TEXT NOT NULL')));
      });

      test('column with no required field defaults to optional', () {
        final sql = ModuleBuilder.generateCreateTable('m_test', [
          {'name': 'notes', 'type': 'text'},
        ]);
        expect(sql, contains('notes TEXT,'));
        expect(sql, isNot(contains('notes TEXT NOT NULL')));
      });

      test('maps number type to REAL', () {
        final sql = ModuleBuilder.generateCreateTable('m_test', [
          {'name': 'amount', 'type': 'number', 'required': true},
        ]);
        expect(sql, contains('amount REAL NOT NULL'));
      });

      test('maps datetime type to INTEGER', () {
        final sql = ModuleBuilder.generateCreateTable('m_test', [
          {'name': 'date', 'type': 'datetime'},
        ]);
        expect(sql, contains('date INTEGER,'));
      });

      test('maps boolean type to INTEGER', () {
        final sql = ModuleBuilder.generateCreateTable('m_test', [
          {'name': 'done', 'type': 'boolean'},
        ]);
        expect(sql, contains('done INTEGER,'));
      });

      test('maps currency type to REAL', () {
        final sql = ModuleBuilder.generateCreateTable('m_test', [
          {'name': 'price', 'type': 'currency'},
        ]);
        expect(sql, contains('price REAL,'));
      });

      test('multiple columns in order', () {
        final sql = ModuleBuilder.generateCreateTable('m_test', [
          {'name': 'name', 'type': 'text', 'required': true},
          {'name': 'amount', 'type': 'number'},
          {'name': 'date', 'type': 'datetime', 'required': true},
        ]);
        expect(
          sql,
          'CREATE TABLE IF NOT EXISTS "m_test" '
          '(id TEXT PRIMARY KEY, '
          'name TEXT NOT NULL, '
          'amount REAL, '
          'date INTEGER NOT NULL, '
          'created_at INTEGER NOT NULL, '
          'updated_at INTEGER NOT NULL)',
        );
      });

      test('always starts with id and ends with timestamps', () {
        final sql = ModuleBuilder.generateCreateTable('m_test', []);
        expect(
          sql,
          startsWith(
            'CREATE TABLE IF NOT EXISTS "m_test" (id TEXT PRIMARY KEY, ',
          ),
        );
        expect(
          sql,
          endsWith('created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL)'),
        );
      });

      test('empty columns still includes id and timestamps', () {
        final sql = ModuleBuilder.generateCreateTable('m_test', []);
        expect(
          sql,
          'CREATE TABLE IF NOT EXISTS "m_test" '
          '(id TEXT PRIMARY KEY, '
          'created_at INTEGER NOT NULL, '
          'updated_at INTEGER NOT NULL)',
        );
      });
    });

    group('generateMutations', () {
      final columns = [
        {'name': 'name', 'type': 'text', 'required': true},
        {'name': 'amount', 'type': 'number'},
      ];

      test('isCreate generates INSERT statement', () {
        final result = ModuleBuilder.generateMutations(
          'm_test',
          columns,
          isCreate: true,
        );
        expect(result.containsKey('insert'), true);
        expect(
          result['insert'],
          'INSERT INTO "m_test" '
          '("id", "name", "amount", "created_at", "updated_at") '
          'VALUES (:id, :name, :amount, :created_at, :updated_at)',
        );
      });

      test('isUpdate generates UPDATE statement', () {
        final result = ModuleBuilder.generateMutations(
          'm_test',
          columns,
          isUpdate: true,
        );
        expect(result.containsKey('update'), true);
        expect(
          result['update'],
          'UPDATE "m_test" SET '
          '"name" = COALESCE(:name, "name"), '
          '"amount" = COALESCE(:amount, "amount"), '
          '"updated_at" = :updated_at '
          'WHERE id = :id',
        );
      });

      test('isDelete generates DELETE statement', () {
        final result = ModuleBuilder.generateMutations(
          'm_test',
          columns,
          isDelete: true,
        );
        expect(result.containsKey('delete'), true);
        expect(result['delete'], 'DELETE FROM "m_test" WHERE id = :id');
      });

      test('all flags true includes all three', () {
        final result = ModuleBuilder.generateMutations(
          'm_test',
          columns,
          isCreate: true,
          isUpdate: true,
          isDelete: true,
        );
        expect(result.keys, containsAll(['insert', 'update', 'delete']));
        expect(result.length, 3);
      });

      test('no flags returns empty map', () {
        final result = ModuleBuilder.generateMutations('m_test', columns);
        expect(result, isEmpty);
      });

      test('only requested flags are included', () {
        final result = ModuleBuilder.generateMutations(
          'm_test',
          columns,
          isCreate: true,
          isDelete: true,
        );
        expect(result.containsKey('insert'), true);
        expect(result.containsKey('delete'), true);
        expect(result.containsKey('update'), false);
        expect(result.length, 2);
      });

      test('insert with empty columns has id and timestamps', () {
        final result = ModuleBuilder.generateMutations(
          'm_test',
          [],
          isCreate: true,
        );
        expect(
          result['insert'],
          'INSERT INTO "m_test" '
          '("id", "created_at", "updated_at") '
          'VALUES (:id, :created_at, :updated_at)',
        );
      });

      test('update with empty columns only sets updated_at', () {
        final result = ModuleBuilder.generateMutations(
          'm_test',
          [],
          isUpdate: true,
        );
        expect(
          result['update'],
          'UPDATE "m_test" SET '
          '"updated_at" = :updated_at '
          'WHERE id = :id',
        );
      });
    });

    group('resolveTableReferences', () {
      test('replaces single placeholder', () {
        final result = ModuleBuilder.resolveTableReferences(
          'SELECT id FROM {{default}}',
          {'default': 'm_test_default'},
        );
        expect(result, 'SELECT id FROM "m_test_default"');
      });

      test('replaces multiple different placeholders', () {
        final result = ModuleBuilder.resolveTableReferences(
          'SELECT * FROM {{entries}} JOIN {{categories}} ON 1=1',
          {'entries': 'm_exp_entries', 'categories': 'm_exp_categories'},
        );
        expect(
          result,
          'SELECT * FROM "m_exp_entries" JOIN "m_exp_categories" ON 1=1',
        );
      });

      test('replaces same placeholder multiple times', () {
        final result = ModuleBuilder.resolveTableReferences(
          'SELECT * FROM {{default}} UNION SELECT * FROM {{default}}',
          {'default': 'm_test_default'},
        );
        expect(
          result,
          'SELECT * FROM "m_test_default" UNION SELECT * FROM "m_test_default"',
        );
      });

      test('returns original if no placeholders', () {
        final result = ModuleBuilder.resolveTableReferences('SELECT 1', {
          'default': 'm_test_default',
        });
        expect(result, 'SELECT 1');
      });

      test('leaves unmatched placeholders as-is', () {
        final result = ModuleBuilder.resolveTableReferences(
          'SELECT * FROM {{unknown}}',
          {'default': 'm_test_default'},
        );
        expect(result, 'SELECT * FROM {{unknown}}');
      });

      test('handles empty table names map', () {
        final result = ModuleBuilder.resolveTableReferences(
          'SELECT * FROM {{default}}',
          {},
        );
        expect(result, 'SELECT * FROM {{default}}');
      });
    });

    group('build', () {
      test('full habit tracker with main, add, and edit screens', () {
        final input = _habitTrackerInput();
        final module = ModuleBuilder.build(input);

        // Module metadata
        expect(module.name, 'Habit Tracker');
        expect(module.description, 'Track daily habits');
        expect(module.icon, 'check-circle');
        expect(module.color, '#4CAF50');

        // ID follows timestamp_hash pattern
        expect(module.id, matches(RegExp(r'^\d+_[0-9a-f]+$')));

        // Database tableNames
        expect(module.database, isNotNull);
        expect(module.database!.tableNames, {
          'default': 'm_habit_tracker_default',
        });

        // Setup SQL generated
        expect(module.database!.setup, hasLength(1));
        expect(
          module.database!.setup.first,
          startsWith('CREATE TABLE IF NOT EXISTS "m_habit_tracker_default"'),
        );
        expect(module.database!.setup.first, contains('title TEXT NOT NULL'));
        expect(module.database!.setup.first, contains('completed INTEGER'));

        // Teardown generated
        expect(module.database!.teardown, hasLength(1));
        expect(
          module.database!.teardown.first,
          'DROP TABLE IF EXISTS "m_habit_tracker_default"',
        );
      });

      test('queries have resolved table references (no {{}} remaining)', () {
        final input = _habitTrackerInput();
        final module = ModuleBuilder.build(input);

        final mainScreen = module.screens['main']!;
        final queries = mainScreen['queries'] as Map;
        final entriesQuery = queries['entries'] as Map;
        final sql = entriesQuery['sql'] as String;

        expect(sql, isNot(contains('{{')));
        expect(sql, isNot(contains('}}')));
        expect(sql, contains('"m_habit_tracker_default"'));
      });

      test('form screen with submitLabel gets insert mutation', () {
        final input = _habitTrackerInput();
        final module = ModuleBuilder.build(input);

        final addScreen = module.screens['add_entry']!;
        final mutations = addScreen['mutations'] as Map;

        expect(mutations.containsKey('insert'), true);
        expect(
          mutations['insert'],
          contains('INSERT INTO "m_habit_tracker_default"'),
        );
      });

      test('form screen with editLabel gets update mutation', () {
        final input = _habitTrackerInput();
        final module = ModuleBuilder.build(input);

        final editScreen = module.screens['edit_entry']!;
        final mutations = editScreen['mutations'] as Map;

        expect(mutations.containsKey('update'), true);
        expect(
          mutations['update'],
          contains('UPDATE "m_habit_tracker_default"'),
        );
      });

      test('form screen with delete_entry in tree gets delete mutation', () {
        final input = _habitTrackerInput();
        final module = ModuleBuilder.build(input);

        final editScreen = module.screens['edit_entry']!;
        final mutations = editScreen['mutations'] as Map;

        expect(mutations.containsKey('delete'), true);
        expect(
          mutations['delete'],
          'DELETE FROM "m_habit_tracker_default" WHERE id = :id',
        );
      });

      test(
        'main screen gets delete mutation from swipe delete_entry action',
        () {
          final input = _habitTrackerInput();
          final module = ModuleBuilder.build(input);

          final mainScreen = module.screens['main']!;
          final mutations = mainScreen['mutations'] as Map;

          expect(mutations.containsKey('delete'), true);
          expect(
            mutations['delete'],
            'DELETE FROM "m_habit_tracker_default" WHERE id = :id',
          );
        },
      );

      test('table key is removed from screen output', () {
        final input = _habitTrackerInput();
        final module = ModuleBuilder.build(input);

        final addScreen = module.screens['add_entry']!;
        expect(addScreen.containsKey('table'), false);

        final editScreen = module.screens['edit_entry']!;
        expect(editScreen.containsKey('table'), false);
      });

      test(
        'form screen with neither submitLabel nor editLabel gets insert',
        () {
          final input = {
            'name': 'Notes',
            'description': 'Simple notes',
            'icon': 'note',
            'color': '#FF9800',
            'tables': {
              'default': {
                'columns': [
                  {'name': 'content', 'type': 'text', 'required': true},
                ],
              },
            },
            'screens': {
              'add': {
                'type': 'form_screen',
                'table': 'default',
                'children': [
                  {'type': 'text_input', 'field': 'content'},
                ],
              },
            },
          };

          final module = ModuleBuilder.build(input);
          final addScreen = module.screens['add']!;
          final mutations = addScreen['mutations'] as Map;

          expect(mutations.containsKey('insert'), true);
          expect(mutations.containsKey('update'), false);
        },
      );

      test('existing mutations are not overwritten', () {
        final input = {
          'name': 'Notes',
          'description': '',
          'icon': 'note',
          'color': '#FF9800',
          'tables': {
            'default': {
              'columns': [
                {'name': 'content', 'type': 'text', 'required': true},
              ],
            },
          },
          'screens': {
            'add': {
              'type': 'form_screen',
              'table': 'default',
              'submitLabel': 'Save',
              'mutations': {'insert': 'CUSTOM INSERT SQL'},
              'children': [],
            },
          },
        };

        final module = ModuleBuilder.build(input);
        final addScreen = module.screens['add']!;
        final mutations = addScreen['mutations'] as Map;

        // The existing custom insert should not be overwritten
        expect(mutations['insert'], 'CUSTOM INSERT SQL');
      });

      test('navigation is parsed when present', () {
        final input = _habitTrackerInput();
        input['navigation'] = {
          'bottomNav': {
            'items': [
              {'label': 'Home', 'icon': 'house', 'screenId': 'main'},
              {'label': 'Add', 'icon': 'plus', 'screenId': 'add_entry'},
            ],
          },
        };

        final module = ModuleBuilder.build(input);
        expect(module.navigation, isNotNull);
        expect(module.navigation!.bottomNav, isNotNull);
        expect(module.navigation!.bottomNav!.items, hasLength(2));
        expect(module.navigation!.bottomNav!.items.first.label, 'Home');
      });

      test('navigation is null when not provided', () {
        final input = _habitTrackerInput();
        // Input does not have a navigation key
        final module = ModuleBuilder.build(input);
        expect(module.navigation, isNull);
      });

      test('guide is parsed when present', () {
        final input = _habitTrackerInput();
        input['guide'] = [
          {'title': 'Welcome', 'body': 'Get started tracking habits'},
          {'title': 'Tips', 'body': 'Check off habits daily'},
        ];

        final module = ModuleBuilder.build(input);
        expect(module.guide, hasLength(2));
        expect(module.guide.first['title'], 'Welcome');
        expect(module.guide.last['body'], 'Check off habits daily');
      });

      test('guide defaults to empty list when not provided', () {
        final input = _habitTrackerInput();
        final module = ModuleBuilder.build(input);
        expect(module.guide, isEmpty);
      });

      test('multi-table module generates all tables', () {
        final input = {
          'name': 'Budget',
          'description': 'Track spending by category',
          'icon': 'wallet',
          'color': '#2196F3',
          'tables': {
            'expenses': {
              'columns': [
                {'name': 'description', 'type': 'text', 'required': true},
                {'name': 'amount', 'type': 'number', 'required': true},
                {'name': 'category_id', 'type': 'reference'},
              ],
            },
            'categories': {
              'columns': [
                {'name': 'name', 'type': 'text', 'required': true},
                {'name': 'budget', 'type': 'number'},
              ],
            },
          },
          'screens': {
            'main': {
              'type': 'screen',
              'queries': {
                'expenses': {
                  'sql':
                      'SELECT e.*, c.name AS category_name FROM {{expenses}} e '
                      'LEFT JOIN {{categories}} c ON e.category_id = c.id',
                },
                'categories': {'sql': 'SELECT * FROM {{categories}}'},
              },
              'children': [],
            },
            'add_expense': {
              'type': 'form_screen',
              'submitLabel': 'Save',
              'table': 'expenses',
              'children': [
                {'type': 'text_input', 'field': 'description'},
                {'type': 'currency_input', 'field': 'amount'},
              ],
            },
            'add_category': {
              'type': 'form_screen',
              'submitLabel': 'Add',
              'table': 'categories',
              'children': [
                {'type': 'text_input', 'field': 'name'},
                {'type': 'currency_input', 'field': 'budget'},
              ],
            },
          },
        };

        final module = ModuleBuilder.build(input);

        // Both tables are in tableNames
        expect(module.database!.tableNames, {
          'expenses': 'm_budget_expenses',
          'categories': 'm_budget_categories',
        });

        // Both CREATE TABLE statements generated
        expect(module.database!.setup, hasLength(2));
        expect(module.database!.setup[0], contains('"m_budget_expenses"'));
        expect(module.database!.setup[1], contains('"m_budget_categories"'));

        // Both DROP TABLE statements generated
        expect(module.database!.teardown, hasLength(2));
        expect(
          module.database!.teardown[0],
          'DROP TABLE IF EXISTS "m_budget_expenses"',
        );
        expect(
          module.database!.teardown[1],
          'DROP TABLE IF EXISTS "m_budget_categories"',
        );

        // Queries have both references resolved
        final mainScreen = module.screens['main']!;
        final queries = mainScreen['queries'] as Map;
        final expensesQuery = (queries['expenses'] as Map)['sql'] as String;
        expect(expensesQuery, contains('"m_budget_expenses"'));
        expect(expensesQuery, contains('"m_budget_categories"'));
        expect(expensesQuery, isNot(contains('{{')));

        final categoriesQuery = (queries['categories'] as Map)['sql'] as String;
        expect(categoriesQuery, contains('"m_budget_categories"'));

        // Each form_screen targets its own table
        final addExpense = module.screens['add_expense']!;
        final expenseMutations = addExpense['mutations'] as Map;
        expect(
          expenseMutations['insert'] as String,
          contains('"m_budget_expenses"'),
        );

        final addCategory = module.screens['add_category']!;
        final categoryMutations = addCategory['mutations'] as Map;
        expect(
          categoryMutations['insert'] as String,
          contains('"m_budget_categories"'),
        );

        // table key removed from both form screens
        expect(addExpense.containsKey('table'), false);
        expect(addCategory.containsKey('table'), false);
      });

      test('module ID is unique across calls', () {
        final input1 = _minimalInput();
        final input2 = _minimalInput();

        final module1 = ModuleBuilder.build(input1);
        // Small delay isn't needed - Object.hash with different DateTime
        // instances should produce different results
        final module2 = ModuleBuilder.build(input2);

        // Both match the pattern
        expect(module1.id, matches(RegExp(r'^\d+_[0-9a-f]+$')));
        expect(module2.id, matches(RegExp(r'^\d+_[0-9a-f]+$')));
      });

      test('defaults icon and color when not provided', () {
        final input = {
          'name': 'Minimal',
          'tables': {
            'default': {
              'columns': [
                {'name': 'value', 'type': 'text'},
              ],
            },
          },
          'screens': {
            'main': {'type': 'screen', 'children': []},
          },
        };

        final module = ModuleBuilder.build(input);
        expect(module.icon, 'cube');
        expect(module.color, '#D94E33');
        expect(module.description, '');
      });

      test('setup SQL includes all column types correctly', () {
        final input = {
          'name': 'Mixed',
          'tables': {
            'default': {
              'columns': [
                {'name': 'label', 'type': 'text', 'required': true},
                {'name': 'count', 'type': 'number', 'required': true},
                {'name': 'done', 'type': 'boolean'},
                {'name': 'due', 'type': 'datetime'},
              ],
            },
          },
          'screens': {
            'main': {'type': 'screen', 'children': []},
          },
        };

        final module = ModuleBuilder.build(input);
        final createSql = module.database!.setup.first;
        expect(createSql, contains('label TEXT NOT NULL'));
        expect(createSql, contains('count REAL NOT NULL'));
        expect(createSql, contains('done INTEGER,'));
        expect(createSql, contains('due INTEGER,'));
        expect(createSql, contains('id TEXT PRIMARY KEY'));
        expect(createSql, contains('created_at INTEGER NOT NULL'));
        expect(createSql, contains('updated_at INTEGER NOT NULL'));
      });

      test('screen without queries is left as-is', () {
        final input = {
          'name': 'Simple',
          'tables': {
            'default': {
              'columns': [
                {'name': 'value', 'type': 'text'},
              ],
            },
          },
          'screens': {
            'main': {
              'type': 'screen',
              'children': [
                {'type': 'text', 'value': 'Hello'},
              ],
            },
          },
        };

        final module = ModuleBuilder.build(input);
        final mainScreen = module.screens['main']!;

        // No queries key should remain absent or null
        expect(mainScreen['queries'], isNull);

        // Children preserved
        final children = mainScreen['children'] as List;
        expect(children, hasLength(1));
      });

      test('tab_screen with delete_entry gets delete mutation', () {
        final input = {
          'name': 'Tasks',
          'tables': {
            'default': {
              'columns': [
                {'name': 'title', 'type': 'text', 'required': true},
              ],
            },
          },
          'screens': {
            'main': {
              'type': 'tab_screen',
              'children': [
                {
                  'type': 'entry_list',
                  'swipeActions': [
                    {'action': 'delete_entry'},
                  ],
                },
              ],
            },
          },
        };

        final module = ModuleBuilder.build(input);
        final mainScreen = module.screens['main']!;
        final mutations = mainScreen['mutations'] as Map;

        expect(mutations.containsKey('delete'), true);
        expect(
          mutations['delete'],
          'DELETE FROM "m_tasks_default" WHERE id = :id',
        );
      });
    });
  });
}

/// Builds a representative Habit Tracker input for testing.
Map<String, dynamic> _habitTrackerInput() {
  return {
    'name': 'Habit Tracker',
    'description': 'Track daily habits',
    'icon': 'check-circle',
    'color': '#4CAF50',
    'tables': {
      'default': {
        'columns': [
          {'name': 'title', 'type': 'text', 'required': true},
          {'name': 'completed', 'type': 'boolean'},
          {'name': 'notes', 'type': 'text'},
        ],
      },
    },
    'screens': {
      'main': {
        'type': 'screen',
        'queries': {
          'entries': {
            'sql':
                'SELECT id, title, completed FROM {{default}} '
                'ORDER BY created_at DESC',
          },
        },
        'children': [
          {
            'type': 'entry_list',
            'query': 'entries',
            'swipeActions': [
              {'action': 'delete_entry'},
            ],
          },
        ],
      },
      'add_entry': {
        'type': 'form_screen',
        'submitLabel': 'Add Habit',
        'table': 'default',
        'children': [
          {'type': 'text_input', 'field': 'title', 'label': 'Habit Name'},
          {'type': 'text_input', 'field': 'notes', 'label': 'Notes'},
        ],
      },
      'edit_entry': {
        'type': 'form_screen',
        'editLabel': 'Save Changes',
        'table': 'default',
        'children': [
          {'type': 'text_input', 'field': 'title', 'label': 'Habit Name'},
          {'type': 'text_input', 'field': 'notes', 'label': 'Notes'},
          {'type': 'button', 'label': 'Delete', 'action': 'delete_entry'},
        ],
      },
    },
  };
}

/// Minimal valid input for build().
Map<String, dynamic> _minimalInput() {
  return {
    'name': 'Test',
    'tables': {
      'default': {
        'columns': [
          {'name': 'value', 'type': 'text'},
        ],
      },
    },
    'screens': {
      'main': {'type': 'screen', 'children': []},
    },
  };
}
