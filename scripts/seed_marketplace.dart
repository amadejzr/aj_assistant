/// Seeds `marketplace_templates` in Firestore with starter templates.
///
/// Run:
///   cd scripts && make seed
///
/// Requires a service account key at scripts/service-account.json.
/// Get one from: Firebase Console → Project Settings → Service Accounts
library;

import 'dart:io';

import '../lib/features/blueprint/dsl/blueprint_dsl.dart';
import 'package:dart_firebase_admin/dart_firebase_admin.dart';
import 'package:dart_firebase_admin/firestore.dart' hide Query;
import 'templates/hiking.dart';

Future<void> main() async {
  final admin = FirebaseAdminApp.initializeApp(
    'assistant-16a63',
    Credential.fromServiceAccount(File('service-account.json')),
  );

  final firestore = Firestore(admin);
  final collection = firestore.collection('marketplace_templates');

  final templates = {
    'savings_goals': _savingsGoals(),
    'hiking_journal': hikingTemplate(),
  };

  for (final entry in templates.entries) {
    print('Writing ${entry.key}...');
    await collection.doc(entry.key).set(entry.value);
  }

  print('Done — ${templates.length} templates seeded.');
  await admin.close();
}

Json _savingsGoals() => TemplateDef.build(
  name: 'Savings Goals',
  description: 'Set targets, log deposits, watch your savings grow',
  longDescription:
      'Track multiple savings goals with automatic progress tracking. '
      'Log each deposit and see your progress at a glance. Whether you\'re '
      'saving for an emergency fund, a vacation, or a big purchase — set '
      'your target, log your deposits, and watch the progress bars fill up.',
  icon: 'piggy-bank',
  color: '#2E7D32',
  category: 'Finance',
  tags: ['savings', 'goals', 'money', 'finance', 'budget', 'deposits'],
  featured: true,
  sortOrder: 1,
  guide: [
    Guide.step(
      title: 'Create a Goal',
      body: 'Tap + to add a savings goal. Give it a name, set your target '
          'amount, and optionally pick a deadline.',
    ),
    Guide.step(
      title: 'Log Deposits',
      body: 'Switch to the History tab and tap + to log a deposit. Pick '
          'which goal it\'s for, enter the amount, and it\'s automatically '
          'tracked.',
    ),
    Guide.step(
      title: 'Track Progress',
      body: 'The Dashboard shows your total savings and progress bars for '
          'each active goal. Watch them fill up as you save!',
    ),
  ],
  navigation: Nav.bottomNav(items: [
    Nav.item(label: 'Dashboard', icon: 'chart-line-up', screenId: 'main'),
    Nav.item(label: 'Goals', icon: 'target', screenId: 'goals_list'),
    Nav.item(label: 'History', icon: 'clock-counter-clockwise', screenId: 'history'),
  ]),
  database: Db.build(
    tableNames: {
      'goal': 'm_savings_goals',
      'deposit': 'm_savings_deposits',
    },
    setup: [
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
    teardown: [
      'DROP TABLE IF EXISTS "m_savings_deposits"',
      'DROP TABLE IF EXISTS "m_savings_goals"',
    ],
  ),
  screens: {
    // ═══════════════════════════════════════════
    //  HOME — Dashboard
    // ═══════════════════════════════════════════
    'main': Layout.screen(
      appBar: Layout.appBar(title: 'Savings Goals', showBack: false),
      queries: {
        'total_saved': Query.def(
          'SELECT COALESCE(SUM(saved_amount), 0) as total '
          'FROM "m_savings_goals"',
        ),
        'active_count': Query.def(
          'SELECT COUNT(*) as total '
          'FROM "m_savings_goals" WHERE status = \'Active\'',
        ),
        'active_goals': Query.def(
          'SELECT id, name, target_amount, saved_amount, category, deadline '
          'FROM "m_savings_goals" '
          'WHERE status = \'Active\' ORDER BY name',
        ),
      },
      children: [
        Layout.scrollColumn(children: [
          Layout.row(children: [
            Display.statCard(
              label: 'Total Saved',
              format: 'currency',
              accent: true,
              source: 'total_saved',
              valueKey: 'total',
            ),
            Display.statCard(
              label: 'Active Goals',
              source: 'active_count',
              valueKey: 'total',
            ),
          ]),
          Display.entryList(
            title: 'Active Goals',
            source: 'active_goals',
            emptyState: Display.emptyState(
              message: 'No goals yet',
              icon: 'target',
              action: Act.navigate('add_goal', label: 'Create your first goal'),
            ),
            itemLayout: Display.entryCard(
              title: '{{name}}',
              subtitle: r'${{saved_amount}} / ${{target_amount}}',
              trailing: '{{category}}',
              onTap: Act.navigate(
                'view_goal',
                forwardFields: [
                  'name', 'target_amount', 'saved_amount',
                  'deadline', 'category', 'status', 'notes',
                ],
                params: {},
              ),
            ),
          ),
        ]),
      ],
      fab: Actions.fab(
        icon: 'add',
        action: Act.navigate('add_goal', params: {}),
      ),
    ),

    // ═══════════════════════════════════════════
    //  GOALS — Full list
    // ═══════════════════════════════════════════
    'goals_list': Layout.screen(
      appBar: Layout.appBar(title: 'Goals', showBack: false),
      queries: {
        'goals': Query.def(
          'SELECT id, name, target_amount, saved_amount, '
          'deadline, category, status '
          'FROM "m_savings_goals" ORDER BY deadline ASC',
        ),
      },
      mutations: {
        'delete': Mut.sql('DELETE FROM "m_savings_goals" WHERE id = :id'),
      },
      children: [
        Display.entryList(
          source: 'goals',
          emptyState: Display.emptyState(
            message: 'No goals yet',
            icon: 'target',
            action: Act.navigate('add_goal', label: 'Create a goal'),
          ),
          itemLayout: Display.entryCard(
            title: '{{name}}',
            subtitle: '{{deadline}}',
            trailing: '{{status}}',
            onTap: Act.navigate(
              'view_goal',
              forwardFields: [
                'name', 'target_amount', 'saved_amount',
                'deadline', 'category', 'status', 'notes',
              ],
              params: {},
            ),
            swipeActions: {
              'right': Act.confirm(
                title: 'Delete Goal',
                message: 'Delete this goal and all its deposits?',
                onConfirm: Act.deleteEntry(),
              ),
            },
          ),
        ),
      ],
      fab: Actions.fab(
        icon: 'add',
        action: Act.navigate('add_goal', params: {}),
      ),
    ),

    // ═══════════════════════════════════════════
    //  HISTORY — Deposit log
    // ═══════════════════════════════════════════
    'history': Layout.screen(
      appBar: Layout.appBar(title: 'History', showBack: false),
      queries: {
        'deposits': Query.def(
          'SELECT d.id, d.amount, d.note, d.date, '
          'g.name as goal_name '
          'FROM "m_savings_deposits" d '
          'LEFT JOIN "m_savings_goals" g ON d.goal_id = g.id '
          'ORDER BY d.date DESC',
        ),
        'total_deposited': Query.def(
          'SELECT COALESCE(SUM(amount), 0) as total '
          'FROM "m_savings_deposits"',
        ),
      },
      mutations: {
        'delete': Mut.sql('DELETE FROM "m_savings_deposits" WHERE id = :id'),
      },
      children: [
        Layout.scrollColumn(children: [
          Display.statCard(
            label: 'Total Deposited',
            format: 'currency',
            source: 'total_deposited',
            valueKey: 'total',
          ),
          Display.entryList(
            source: 'deposits',
            itemLayout: Display.entryCard(
              title: '{{goal_name}}',
              subtitle: '{{note}}',
              trailing: '{{amount}}',
              trailingFormat: 'currency',
              onTap: Act.navigate(
                'edit_deposit',
                forwardFields: ['amount', 'goal_id', 'date', 'note'],
                params: {},
              ),
              swipeActions: {
                'right': Act.confirm(
                  title: 'Delete Deposit',
                  message: 'Delete this deposit? Goal balance will be adjusted.',
                  onConfirm: Act.deleteEntry(),
                ),
              },
            ),
          ),
        ]),
      ],
      fab: Actions.fab(
        icon: 'add',
        action: Act.navigate('add_deposit', params: {}),
      ),
    ),

    // ═══════════════════════════════════════════
    //  VIEW GOAL — Detail + deposits for this goal
    // ═══════════════════════════════════════════
    'view_goal': Layout.screen(
      appBar: Layout.appBar(title: '{{name}}'),
      queries: {
        'goal_deposits': Query.def(
          'SELECT id, amount, note, date '
          'FROM "m_savings_deposits" '
          'WHERE goal_id = :id ORDER BY date DESC',
          params: {'id': '{{_entryId}}'},
        ),
      },
      mutations: {
        'delete': Mut.sql('DELETE FROM "m_savings_goals" WHERE id = :id'),
      },
      children: [
        Layout.scrollColumn(children: [
          Display.progressBar(
            label: 'Saved',
            value: '{{saved_amount}}',
            max: '{{target_amount}}',
          ),
          Layout.row(children: [
            Display.statCard(
              label: 'Saved',
              format: 'currency',
              value: '{{saved_amount}}',
            ),
            Display.statCard(
              label: 'Target',
              format: 'currency',
              value: '{{target_amount}}',
            ),
          ]),
          Layout.section(
            title: 'Details',
            children: [
              Display.textDisplay(label: 'Category', value: '{{category}}'),
              Display.textDisplay(label: 'Deadline', value: '{{deadline}}'),
              Display.textDisplay(label: 'Status', value: '{{status}}'),
              Display.textDisplay(label: 'Notes', value: '{{notes}}'),
            ],
          ),
          Display.entryList(
            title: 'Deposits',
            source: 'goal_deposits',
            itemLayout: Display.entryCard(
              title: '{{note}}',
              trailing: '{{amount}}',
              trailingFormat: 'currency',
            ),
          ),
        ]),
      ],
      fab: Actions.fab(
        icon: 'add',
        action: Act.navigate('add_deposit', params: {'goal_id': '{{_entryId}}'}),
      ),
      appBarActions: [
        Actions.iconButton(
          icon: 'pencil',
          action: Act.navigate(
            'edit_goal',
            forwardFields: [
              'name', 'target_amount', 'deadline',
              'category', 'status', 'notes',
            ],
            params: {},
          ),
        ),
        Actions.iconButton(
          icon: 'trash',
          action: Act.confirm(
            title: 'Delete Goal',
            message: 'Delete this goal and all its deposits?',
            onConfirm: Act.deleteEntry(),
          ),
        ),
      ],
    ),

    // ═══════════════════════════════════════════
    //  FORMS
    // ═══════════════════════════════════════════
    'add_goal': Layout.formScreen(
      title: 'New Goal',
      submitLabel: 'Save Goal',
      defaults: {'status': 'Active', 'category': 'Other'},
      mutations: {
        'create': Mut.sql(
          'INSERT INTO "m_savings_goals" '
          '(id, name, target_amount, saved_amount, deadline, category, status, notes, created_at, updated_at) '
          'VALUES (:id, :name, :target_amount, 0, :deadline, :category, :status, :notes, :created_at, :updated_at)',
        ),
      },
      children: [
        Inputs.textInput(
          fieldKey: 'name', label: 'Goal Name', required: true,
          validation: {'required': true, 'minLength': 1, 'message': 'Give your goal a name'},
        ),
        Inputs.numberInput(
          fieldKey: 'target_amount', label: 'Target Amount', required: true,
          validation: {'required': true, 'min': 0.01, 'message': 'Enter a valid amount'},
        ),
        Inputs.datePicker(
          fieldKey: 'deadline', label: 'Target Date',
          validation: {'minDate': 'today', 'message': 'Deadline must be in the future'},
        ),
        Inputs.enumSelector(
          fieldKey: 'category', label: 'Category',
          options: ['Emergency', 'Travel', 'Purchase', 'Education', 'Retirement', 'Other'],
        ),
        Inputs.enumSelector(
          fieldKey: 'status', label: 'Status',
          options: ['Active', 'Completed', 'Paused'],
        ),
        Inputs.textInput(fieldKey: 'notes', label: 'Notes'),
      ],
    ),

    'edit_goal': Layout.formScreen(
      title: 'Edit Goal',
      editLabel: 'Update',
      mutations: {
        'update': Mut.sql(
          'UPDATE "m_savings_goals" SET '
          'name = COALESCE(:name, name), '
          'target_amount = COALESCE(:target_amount, target_amount), '
          'deadline = COALESCE(:deadline, deadline), '
          'category = COALESCE(:category, category), '
          'status = COALESCE(:status, status), '
          'notes = COALESCE(:notes, notes), '
          'updated_at = :updated_at '
          'WHERE id = :id',
        ),
      },
      children: [
        Inputs.textInput(
          fieldKey: 'name', label: 'Goal Name', required: true,
          validation: {'required': true, 'minLength': 1, 'message': 'Give your goal a name'},
        ),
        Inputs.numberInput(
          fieldKey: 'target_amount', label: 'Target Amount', required: true,
          validation: {'required': true, 'min': 0.01, 'message': 'Enter a valid amount'},
        ),
        Inputs.datePicker(fieldKey: 'deadline', label: 'Target Date'),
        Inputs.enumSelector(
          fieldKey: 'category', label: 'Category',
          options: ['Emergency', 'Travel', 'Purchase', 'Education', 'Retirement', 'Other'],
        ),
        Inputs.enumSelector(
          fieldKey: 'status', label: 'Status',
          options: ['Active', 'Completed', 'Paused'],
        ),
        Inputs.textInput(fieldKey: 'notes', label: 'Notes'),
      ],
    ),

    'add_deposit': Layout.formScreen(
      title: 'New Deposit',
      submitLabel: 'Save Deposit',
      queries: {
        'available_goals': Query.def(
          'SELECT id, name FROM "m_savings_goals" WHERE status = \'Active\' ORDER BY name',
        ),
      },
      mutations: {
        'create': Mut.sql(
          'INSERT INTO "m_savings_deposits" '
          '(id, amount, goal_id, date, note, created_at, updated_at) '
          'VALUES (:id, :amount, :goal_id, :date, :note, :created_at, :updated_at)',
        ),
      },
      children: [
        Inputs.referencePicker(
          fieldKey: 'goal_id',
          schemaKey: 'goal',
          displayField: 'name',
          source: 'available_goals',
          label: 'Goal',
          required: true,
          emptyLabel: 'No goals yet',
          emptyAction: Act.navigate('add_goal', params: {}),
        ),
        Inputs.numberInput(
          fieldKey: 'amount', label: 'Amount', required: true,
          validation: {'required': true, 'min': 0.01, 'message': 'Enter a valid amount'},
        ),
        Inputs.datePicker(fieldKey: 'date', label: 'Date', required: true),
        Inputs.textInput(fieldKey: 'note', label: 'Note'),
      ],
    ),

    'edit_deposit': Layout.formScreen(
      title: 'Edit Deposit',
      editLabel: 'Update',
      queries: {
        'available_goals': Query.def(
          'SELECT id, name FROM "m_savings_goals" WHERE status = \'Active\' ORDER BY name',
        ),
      },
      mutations: {
        'update': Mut.sql(
          'UPDATE "m_savings_deposits" SET '
          'amount = COALESCE(:amount, amount), '
          'goal_id = COALESCE(:goal_id, goal_id), '
          'date = COALESCE(:date, date), '
          'note = COALESCE(:note, note), '
          'updated_at = :updated_at '
          'WHERE id = :id',
        ),
      },
      children: [
        Inputs.referencePicker(
          fieldKey: 'goal_id',
          schemaKey: 'goal',
          displayField: 'name',
          source: 'available_goals',
          label: 'Goal',
          required: true,
          emptyLabel: 'No goals yet',
          emptyAction: Act.navigate('add_goal', params: {}),
        ),
        Inputs.numberInput(fieldKey: 'amount', label: 'Amount', required: true),
        Inputs.datePicker(fieldKey: 'date', label: 'Date', required: true),
        Inputs.textInput(fieldKey: 'note', label: 'Note'),
      ],
    ),
  },
);
