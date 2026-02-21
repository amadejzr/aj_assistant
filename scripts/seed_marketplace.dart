/// Seeds `marketplace_templates` in Firestore with starter templates.
///
/// Run:
///   cd scripts && make seed
///
/// Requires a service account key at scripts/service-account.json.
/// Get one from: Firebase Console → Project Settings → Service Accounts
library;

import 'dart:io';

import 'package:dart_firebase_admin/dart_firebase_admin.dart';
import 'package:dart_firebase_admin/firestore.dart';


Future<void> main() async {
  final admin = FirebaseAdminApp.initializeApp(
    'assistant-16a63',
    Credential.fromServiceAccount(File('service-account.json')),
  );

  final firestore = Firestore(admin);
  final collection = firestore.collection('marketplace_templates');

  final templates = {
    'savings_goals': {
      'name': 'Savings Goals',
      'description': 'Set targets, log deposits, watch your savings grow',
      'longDescription':
          'Track multiple savings goals with automatic progress tracking. '
          'Log each deposit and see your progress at a glance. Whether you\'re '
          'saving for an emergency fund, a vacation, or a big purchase — set '
          'your target, log your deposits, and watch the progress bars fill up.',
      'icon': 'piggy-bank',
      'color': '#2E7D32',
      'category': 'Finance',
      'tags': ['savings', 'goals', 'money', 'finance', 'budget', 'deposits'],
      'featured': true,
      'sortOrder': 1,
      'installCount': 0,
      'version': 1,
      'settings': <String, dynamic>{},
      'guide': [
        {
          'title': 'Create a Goal',
          'body':
              'Tap + to add a savings goal. Give it a name, set your target '
              'amount, and optionally pick a deadline.',
        },
        {
          'title': 'Log Deposits',
          'body':
              'Switch to the History tab and tap + to log a deposit. Pick '
              'which goal it\'s for, enter the amount, and it\'s automatically '
              'tracked.',
        },
        {
          'title': 'Track Progress',
          'body':
              'The Dashboard shows your total savings and progress bars for '
              'each active goal. Watch them fill up as you save!',
        },
      ],

      // ─── Navigation ───
      'navigation': {
        'bottomNav': {
          'items': [
            {'label': 'Dashboard', 'icon': 'chart-line-up', 'screenId': 'main'},
            {'label': 'Goals', 'icon': 'target', 'screenId': 'goals_list'},
            {
              'label': 'History',
              'icon': 'clock-counter-clockwise',
              'screenId': 'history',
            },
          ],
        },
      },

      // ─── Database ───
      //
      // SQL tables owned by this module. SchemaManager runs setup[] on install.
      // Triggers auto-update saved_amount on goals when deposits change.
      'database': {
        'tableNames': {
          'goal': 'm_savings_goals',
          'deposit': 'm_savings_deposits',
        },
        'setup': [
          // Goals table
          '''CREATE TABLE IF NOT EXISTS "m_savings_goals" (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            target_amount REAL NOT NULL DEFAULT 0,
            saved_amount REAL NOT NULL DEFAULT 0,
            deadline INTEGER,
            category TEXT NOT NULL DEFAULT 'Other',
            status TEXT NOT NULL DEFAULT 'Active',
            notes TEXT,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )''',

          // Deposits table
          '''CREATE TABLE IF NOT EXISTS "m_savings_deposits" (
            id TEXT PRIMARY KEY,
            amount REAL NOT NULL,
            goal_id TEXT NOT NULL REFERENCES "m_savings_goals"(id),
            date INTEGER NOT NULL,
            note TEXT,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )''',

          // Indexes
          'CREATE INDEX IF NOT EXISTS "idx_sgoals_status" ON "m_savings_goals" (status)',
          'CREATE INDEX IF NOT EXISTS "idx_sgoals_deadline" ON "m_savings_goals" (deadline)',
          'CREATE INDEX IF NOT EXISTS "idx_sdep_goal" ON "m_savings_deposits" (goal_id)',
          'CREATE INDEX IF NOT EXISTS "idx_sdep_date" ON "m_savings_deposits" (date)',

          // Triggers: deposit adds to goal saved_amount
          '''CREATE TRIGGER IF NOT EXISTS "trg_sdep_add"
            AFTER INSERT ON "m_savings_deposits"
            FOR EACH ROW BEGIN
              UPDATE "m_savings_goals"
              SET saved_amount = saved_amount + NEW.amount
              WHERE id = NEW.goal_id;
            END''',

          '''CREATE TRIGGER IF NOT EXISTS "trg_sdep_remove"
            AFTER DELETE ON "m_savings_deposits"
            FOR EACH ROW BEGIN
              UPDATE "m_savings_goals"
              SET saved_amount = saved_amount - OLD.amount
              WHERE id = OLD.goal_id;
            END''',

          '''CREATE TRIGGER IF NOT EXISTS "trg_sdep_adjust"
            AFTER UPDATE OF amount ON "m_savings_deposits"
            FOR EACH ROW BEGIN
              UPDATE "m_savings_goals"
              SET saved_amount = saved_amount + (NEW.amount - OLD.amount)
              WHERE id = NEW.goal_id;
            END''',

          // Cascade delete deposits when goal is deleted
          '''CREATE TRIGGER IF NOT EXISTS "trg_sgoals_cascade_delete"
            BEFORE DELETE ON "m_savings_goals"
            FOR EACH ROW BEGIN
              DELETE FROM "m_savings_deposits" WHERE goal_id = OLD.id;
            END''',
        ],
        'teardown': [
          'DROP TABLE IF EXISTS "m_savings_deposits"',
          'DROP TABLE IF EXISTS "m_savings_goals"',
        ],
      },

      // ─── Screens ───
      'screens': {
        // ═══════════════════════════════════════════
        //  HOME — Dashboard
        // ═══════════════════════════════════════════
        'main': {
          'type': 'screen',
          'appBar': {
            'type': 'app_bar',
            'title': 'Savings Goals',
            'showBack': false,
          },
          'queries': {
            'total_saved': {
              'sql':
                  'SELECT COALESCE(SUM(saved_amount), 0) as total '
                  'FROM "m_savings_goals"',
            },
            'active_count': {
              'sql':
                  'SELECT COUNT(*) as total '
                  'FROM "m_savings_goals" WHERE status = \'Active\'',
            },
            'active_goals': {
              'sql':
                  'SELECT id, name, target_amount, saved_amount, category, deadline '
                  'FROM "m_savings_goals" '
                  'WHERE status = \'Active\' ORDER BY name',
            },
          },
          'children': [
            {
              'type': 'scroll_column',
              'children': [
                {
                  'type': 'row',
                  'children': [
                    {
                      'type': 'stat_card',
                      'label': 'Total Saved',
                      'stat': 'custom',
                      'format': 'currency',
                      'properties': {
                        'accent': true,
                        'source': 'total_saved',
                        'valueKey': 'total',
                      },
                    },
                    {
                      'type': 'stat_card',
                      'label': 'Active Goals',
                      'stat': 'custom',
                      'properties': {
                        'source': 'active_count',
                        'valueKey': 'total',
                      },
                    },
                  ],
                },
                {
                  'type': 'entry_list',
                  'title': 'Active Goals',
                  'source': 'active_goals',
                  'emptyState': {
                    'message': 'No goals yet',
                    'icon': 'target',
                    'action': {'label': 'Create your first goal', 'type': 'navigate', 'screen': 'add_goal'},
                  },
                  'itemLayout': {
                    'type': 'entry_card',
                    'title': '{{name}}',
                    'subtitle': '\${{saved_amount}} / \${{target_amount}}',
                    'trailing': '{{category}}',
                    'onTap': {
                      'type': 'navigate',
                      'screen': 'view_goal',
                      'forwardFields': [
                        'name', 'target_amount', 'saved_amount',
                        'deadline', 'category', 'status', 'notes',
                      ],
                      'params': {},
                    },
                  },
                },
              ],
            },
          ],
          'fab': {
            'type': 'fab',
            'icon': 'add',
            'action': {
              'type': 'navigate',
              'screen': 'add_goal',
              'params': {},
            },
          },
        },

        // ═══════════════════════════════════════════
        //  GOALS — Full list
        // ═══════════════════════════════════════════
        'goals_list': {
          'type': 'screen',
          'appBar': {
            'type': 'app_bar',
            'title': 'Goals',
            'showBack': false,
          },
          'queries': {
            'goals': {
              'sql':
                  'SELECT id, name, target_amount, saved_amount, '
                  'deadline, category, status '
                  'FROM "m_savings_goals" ORDER BY deadline ASC',
            },
          },
          'mutations': {
            'delete': 'DELETE FROM "m_savings_goals" WHERE id = :id',
          },
          'children': [
            {
              'type': 'entry_list',
              'source': 'goals',
              'emptyState': {
                'message': 'No goals yet',
                'icon': 'target',
                'action': {'label': 'Create a goal', 'type': 'navigate', 'screen': 'add_goal'},
              },
              'itemLayout': {
                'type': 'entry_card',
                'title': '{{name}}',
                'subtitle': '{{deadline}}',
                'trailing': '{{status}}',
                'onTap': {
                  'type': 'navigate',
                  'screen': 'view_goal',
                  'forwardFields': [
                    'name', 'target_amount', 'saved_amount',
                    'deadline', 'category', 'status', 'notes',
                  ],
                  'params': {},
                },
                'swipeActions': {
                  'right': {
                    'type': 'confirm',
                    'title': 'Delete Goal',
                    'message': 'Delete this goal and all its deposits?',
                    'onConfirm': {'type': 'delete_entry'},
                  },
                },
              },
            },
          ],
          'fab': {
            'type': 'fab',
            'icon': 'add',
            'action': {
              'type': 'navigate',
              'screen': 'add_goal',
              'params': {},
            },
          },
        },

        // ═══════════════════════════════════════════
        //  HISTORY — Deposit log
        // ═══════════════════════════════════════════
        'history': {
          'type': 'screen',
          'appBar': {
            'type': 'app_bar',
            'title': 'History',
            'showBack': false,
          },
          'queries': {
            'deposits': {
              'sql':
                  'SELECT d.id, d.amount, d.note, d.date, '
                  'g.name as goal_name '
                  'FROM "m_savings_deposits" d '
                  'LEFT JOIN "m_savings_goals" g ON d.goal_id = g.id '
                  'ORDER BY d.date DESC',
            },
            'total_deposited': {
              'sql':
                  'SELECT COALESCE(SUM(amount), 0) as total '
                  'FROM "m_savings_deposits"',
            },
          },
          'mutations': {
            'delete': 'DELETE FROM "m_savings_deposits" WHERE id = :id',
          },
          'children': [
            {
              'type': 'scroll_column',
              'children': [
                {
                  'type': 'stat_card',
                  'label': 'Total Deposited',
                  'stat': 'custom',
                  'format': 'currency',
                  'properties': {
                    'source': 'total_deposited',
                    'valueKey': 'total',
                  },
                },
                {
                  'type': 'entry_list',
                  'source': 'deposits',
                  'itemLayout': {
                    'type': 'entry_card',
                    'title': '{{goal_name}}',
                    'subtitle': '{{note}}',
                    'trailing': '{{amount}}',
                    'trailingFormat': 'currency',
                    'onTap': {
                      'type': 'navigate',
                      'screen': 'edit_deposit',
                      'forwardFields': ['amount', 'goal_id', 'date', 'note'],
                      'params': {},
                    },
                    'swipeActions': {
                      'right': {
                        'type': 'confirm',
                        'title': 'Delete Deposit',
                        'message':
                            'Delete this deposit? Goal balance will be adjusted.',
                        'onConfirm': {'type': 'delete_entry'},
                      },
                    },
                  },
                },
              ],
            },
          ],
          'fab': {
            'type': 'fab',
            'icon': 'add',
            'action': {
              'type': 'navigate',
              'screen': 'add_deposit',
              'params': {},
            },
          },
        },

        // ═══════════════════════════════════════════
        //  VIEW GOAL — Detail + deposits for this goal
        // ═══════════════════════════════════════════
        'view_goal': {
          'type': 'screen',
          'appBar': {
            'type': 'app_bar',
            'title': '{{name}}',
          },
          'queries': {
            'goal_deposits': {
              'sql':
                  'SELECT id, amount, note, date '
                  'FROM "m_savings_deposits" '
                  'WHERE goal_id = :id ORDER BY date DESC',
              'params': {'id': '{{_entryId}}'},
            },
          },
          'mutations': {
            'delete': 'DELETE FROM "m_savings_goals" WHERE id = :id',
          },
          'children': [
            {
              'type': 'scroll_column',
              'children': [
                {
                  'type': 'progress_bar',
                  'label': 'Saved',
                  'value': '{{saved_amount}}',
                  'max': '{{target_amount}}',
                },
                {
                  'type': 'row',
                  'children': [
                    {
                      'type': 'stat_card',
                      'label': 'Saved',
                      'stat': 'custom',
                      'format': 'currency',
                      'properties': {'value': '{{saved_amount}}'},
                    },
                    {
                      'type': 'stat_card',
                      'label': 'Target',
                      'stat': 'custom',
                      'format': 'currency',
                      'properties': {'value': '{{target_amount}}'},
                    },
                  ],
                },
                {
                  'type': 'section',
                  'title': 'Details',
                  'children': [
                    {
                      'type': 'text_display',
                      'label': 'Category',
                      'value': '{{category}}',
                    },
                    {
                      'type': 'text_display',
                      'label': 'Deadline',
                      'value': '{{deadline}}',
                    },
                    {
                      'type': 'text_display',
                      'label': 'Status',
                      'value': '{{status}}',
                    },
                    {
                      'type': 'text_display',
                      'label': 'Notes',
                      'value': '{{notes}}',
                    },
                  ],
                },
                {
                  'type': 'entry_list',
                  'title': 'Deposits',
                  'source': 'goal_deposits',
                  'itemLayout': {
                    'type': 'entry_card',
                    'title': '{{note}}',
                    'trailing': '{{amount}}',
                    'trailingFormat': 'currency',
                  },
                },
              ],
            },
          ],
          'fab': {
            'type': 'fab',
            'icon': 'add',
            'action': {
              'type': 'navigate',
              'screen': 'add_deposit',
              'params': {'goal_id': '{{_entryId}}'},
            },
          },
          'appBarActions': [
            {
              'type': 'icon_button',
              'icon': 'pencil',
              'action': {
                'type': 'navigate',
                'screen': 'edit_goal',
                'forwardFields': [
                  'name', 'target_amount', 'deadline',
                  'category', 'status', 'notes',
                ],
                'params': {},
              },
            },
            {
              'type': 'icon_button',
              'icon': 'trash',
              'action': {
                'type': 'confirm',
                'title': 'Delete Goal',
                'message': 'Delete this goal and all its deposits?',
                'onConfirm': {'type': 'delete_entry'},
              },
            },
          ],
        },

        // ═══════════════════════════════════════════
        //  FORMS
        // ═══════════════════════════════════════════
        'add_goal': {
          'type': 'form_screen',
          'title': 'New Goal',
          'submitLabel': 'Save Goal',
          'defaults': {'status': 'Active', 'category': 'Other'},
          'mutations': {
            'create':
                'INSERT INTO "m_savings_goals" '
                '(id, name, target_amount, saved_amount, deadline, category, status, notes, created_at, updated_at) '
                'VALUES (:id, :name, :target_amount, 0, :deadline, :category, :status, :notes, :created_at, :updated_at)',
          },
          'children': [
            {'type': 'text_input', 'fieldKey': 'name', 'label': 'Goal Name', 'required': true,
             'validation': {'required': true, 'minLength': 1, 'message': 'Give your goal a name'}},
            {'type': 'number_input', 'fieldKey': 'target_amount', 'label': 'Target Amount', 'required': true,
             'validation': {'required': true, 'min': 0.01, 'message': 'Enter a valid amount'}},
            {'type': 'date_picker', 'fieldKey': 'deadline', 'label': 'Target Date',
             'validation': {'minDate': 'today', 'message': 'Deadline must be in the future'}},
            {
              'type': 'enum_selector',
              'fieldKey': 'category',
              'label': 'Category',
              'options': ['Emergency', 'Travel', 'Purchase', 'Education', 'Retirement', 'Other'],
            },
            {
              'type': 'enum_selector',
              'fieldKey': 'status',
              'label': 'Status',
              'options': ['Active', 'Completed', 'Paused'],
            },
            {'type': 'text_input', 'fieldKey': 'notes', 'label': 'Notes'},
          ],
        },
        'edit_goal': {
          'type': 'form_screen',
          'title': 'Edit Goal',
          'editLabel': 'Update',
          'mutations': {
            'update':
                'UPDATE "m_savings_goals" SET '
                'name = COALESCE(:name, name), '
                'target_amount = COALESCE(:target_amount, target_amount), '
                'deadline = COALESCE(:deadline, deadline), '
                'category = COALESCE(:category, category), '
                'status = COALESCE(:status, status), '
                'notes = COALESCE(:notes, notes), '
                'updated_at = :updated_at '
                'WHERE id = :id',
          },
          'children': [
            {'type': 'text_input', 'fieldKey': 'name', 'label': 'Goal Name', 'required': true,
             'validation': {'required': true, 'minLength': 1, 'message': 'Give your goal a name'}},
            {'type': 'number_input', 'fieldKey': 'target_amount', 'label': 'Target Amount', 'required': true,
             'validation': {'required': true, 'min': 0.01, 'message': 'Enter a valid amount'}},
            {'type': 'date_picker', 'fieldKey': 'deadline', 'label': 'Target Date'},
            {
              'type': 'enum_selector',
              'fieldKey': 'category',
              'label': 'Category',
              'options': ['Emergency', 'Travel', 'Purchase', 'Education', 'Retirement', 'Other'],
            },
            {
              'type': 'enum_selector',
              'fieldKey': 'status',
              'label': 'Status',
              'options': ['Active', 'Completed', 'Paused'],
            },
            {'type': 'text_input', 'fieldKey': 'notes', 'label': 'Notes'},
          ],
        },
        'add_deposit': {
          'type': 'form_screen',
          'title': 'New Deposit',
          'submitLabel': 'Save Deposit',
          'queries': {
            'available_goals': {
              'sql':
                  'SELECT id, name FROM "m_savings_goals" WHERE status = \'Active\' ORDER BY name',
            },
          },
          'mutations': {
            'create':
                'INSERT INTO "m_savings_deposits" '
                '(id, amount, goal_id, date, note, created_at, updated_at) '
                'VALUES (:id, :amount, :goal_id, :date, :note, :created_at, :updated_at)',
          },
          'children': [
            {
              'type': 'reference_picker',
              'fieldKey': 'goal_id',
              'schemaKey': 'goal',
              'displayField': 'name',
              'source': 'available_goals',
              'label': 'Goal',
              'required': true,
              'emptyLabel': 'No goals yet',
              'emptyAction': {
                'type': 'navigate',
                'screen': 'add_goal',
                'params': {},
              },
            },
            {'type': 'number_input', 'fieldKey': 'amount', 'label': 'Amount', 'required': true,
             'validation': {'required': true, 'min': 0.01, 'message': 'Enter a valid amount'}},
            {'type': 'date_picker', 'fieldKey': 'date', 'label': 'Date', 'required': true},
            {'type': 'text_input', 'fieldKey': 'note', 'label': 'Note'},
          ],
        },
        'edit_deposit': {
          'type': 'form_screen',
          'title': 'Edit Deposit',
          'editLabel': 'Update',
          'queries': {
            'available_goals': {
              'sql':
                  'SELECT id, name FROM "m_savings_goals" WHERE status = \'Active\' ORDER BY name',
            },
          },
          'mutations': {
            'update':
                'UPDATE "m_savings_deposits" SET '
                'amount = COALESCE(:amount, amount), '
                'goal_id = COALESCE(:goal_id, goal_id), '
                'date = COALESCE(:date, date), '
                'note = COALESCE(:note, note), '
                'updated_at = :updated_at '
                'WHERE id = :id',
          },
          'children': [
            {
              'type': 'reference_picker',
              'fieldKey': 'goal_id',
              'schemaKey': 'goal',
              'displayField': 'name',
              'source': 'available_goals',
              'label': 'Goal',
              'required': true,
              'emptyLabel': 'No goals yet',
              'emptyAction': {
                'type': 'navigate',
                'screen': 'add_goal',
                'params': {},
              },
            },
            {'type': 'number_input', 'fieldKey': 'amount', 'label': 'Amount', 'required': true},
            {'type': 'date_picker', 'fieldKey': 'date', 'label': 'Date', 'required': true},
            {'type': 'text_input', 'fieldKey': 'note', 'label': 'Note'},
          ],
        },
      },
    },
  };

  for (final entry in templates.entries) {
    print('Writing ${entry.key}...');
    await collection.doc(entry.key).set(entry.value);
  }

  print('Done — ${templates.length} templates seeded.');
  await admin.close();
}
