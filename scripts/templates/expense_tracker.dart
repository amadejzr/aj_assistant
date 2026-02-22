import '../../lib/features/blueprint/dsl/blueprint_dsl.dart';

Json expenseTrackerTemplate() => TemplateDef.build(
  name: 'Expense Tracker',
  description: 'Log expenses, manage categories, and see where your money goes',
  longDescription:
      'A simple yet powerful expense tracker. Log every purchase with a '
      'custom category, then watch the dashboard break down your spending '
      'with charts and stats. Create your own categories to match your '
      'lifestyle — the tracker comes pre-loaded with common ones to get '
      'you started.',
  icon: 'receipt',
  color: '#E65100',
  category: 'Finance',
  tags: ['expenses', 'spending', 'budget', 'money', 'finance', 'tracker'],
  featured: true,
  sortOrder: 3,
  guide: [
    Guide.step(
      title: 'Add an Expense',
      body: 'Tap + to log a new expense. Pick a category, enter the amount, '
          'and add an optional note. The date defaults to today.',
    ),
    Guide.step(
      title: 'Manage Categories',
      body: 'Switch to the Categories tab to add, edit, or delete categories. '
          'Common ones like Food and Transport are already set up for you.',
    ),
    Guide.step(
      title: 'Track Your Spending',
      body: 'The Dashboard shows your monthly total and a breakdown by '
          'category. Use the Expenses tab to browse your full history.',
    ),
  ],

  // ─── Navigation ───
  navigation: Nav.bottomNav(items: [
    Nav.item(label: 'Dashboard', icon: 'chart-pie', screenId: 'main'),
    Nav.item(label: 'Expenses', icon: 'list', screenId: 'expenses'),
    Nav.item(label: 'Categories', icon: 'tag', screenId: 'categories'),
  ]),

  // ─── Database ───
  database: Db.build(
    tableNames: {
      'expense': 'm_expenses',
      'category': 'm_expense_categories',
    },
    setup: [
      // Categories table
      '''CREATE TABLE IF NOT EXISTS "m_expense_categories" (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL UNIQUE,
            icon TEXT NOT NULL DEFAULT 'tag',
            color TEXT NOT NULL DEFAULT '#757575',
            sort_order INTEGER NOT NULL DEFAULT 0,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )''',

      // Expenses table
      '''CREATE TABLE IF NOT EXISTS "m_expenses" (
            id TEXT PRIMARY KEY,
            amount REAL NOT NULL,
            category_id TEXT NOT NULL REFERENCES "m_expense_categories"(id),
            date INTEGER NOT NULL,
            note TEXT,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )''',

      // Indexes
      'CREATE INDEX IF NOT EXISTS "idx_exp_date" ON "m_expenses" (date)',
      'CREATE INDEX IF NOT EXISTS "idx_exp_category" ON "m_expenses" (category_id)',
      'CREATE INDEX IF NOT EXISTS "idx_expcat_sort" ON "m_expense_categories" (sort_order)',

      // Seed default categories
      '''INSERT OR IGNORE INTO "m_expense_categories"
            (id, name, icon, color, sort_order, created_at, updated_at) VALUES
            ('cat_food',        'Food',          'fork-knife',    '#4CAF50', 1, strftime('%s','now')*1000, strftime('%s','now')*1000),
            ('cat_transport',   'Transport',     'car',           '#2196F3', 2, strftime('%s','now')*1000, strftime('%s','now')*1000),
            ('cat_entertainment','Entertainment','ticket',        '#9C27B0', 3, strftime('%s','now')*1000, strftime('%s','now')*1000),
            ('cat_shopping',    'Shopping',      'shopping-bag',  '#FF9800', 4, strftime('%s','now')*1000, strftime('%s','now')*1000),
            ('cat_bills',       'Bills',         'lightning',     '#F44336', 5, strftime('%s','now')*1000, strftime('%s','now')*1000),
            ('cat_health',      'Health',        'heartbeat',     '#00BCD4', 6, strftime('%s','now')*1000, strftime('%s','now')*1000),
            ('cat_other',       'Other',         'dots-three',    '#757575', 7, strftime('%s','now')*1000, strftime('%s','now')*1000)''',
    ],
    teardown: [
      'DROP TABLE IF EXISTS "m_expenses"',
      'DROP TABLE IF EXISTS "m_expense_categories"',
    ],
  ),

  // ─── Screens ───
  screens: {
    // ═══════════════════════════════════════════
    //  DASHBOARD
    // ═══════════════════════════════════════════
    'main': Layout.screen(
      appBar: Layout.appBar(title: 'Expense Tracker', showBack: false),
      queries: {
        'month_total': Query.def(
          'SELECT COALESCE(SUM(amount), 0) as total '
          'FROM "m_expenses" '
          "WHERE date >= strftime('%s', date('now', 'start of month')) * 1000",
        ),
        'expense_count': Query.def(
          'SELECT COUNT(*) as total FROM "m_expenses" '
          "WHERE date >= strftime('%s', date('now', 'start of month')) * 1000",
        ),
        'by_category': Query.def(
          'SELECT c.name as category, COALESCE(SUM(e.amount), 0) as total '
          'FROM "m_expenses" e '
          'JOIN "m_expense_categories" c ON e.category_id = c.id '
          "WHERE e.date >= strftime('%s', date('now', 'start of month')) * 1000 "
          'GROUP BY c.name ORDER BY total DESC',
        ),
        'recent': Query.def(
          'SELECT e.id, e.amount, e.date, e.note, c.name as category_name '
          'FROM "m_expenses" e '
          'JOIN "m_expense_categories" c ON e.category_id = c.id '
          'ORDER BY e.date DESC LIMIT 5',
        ),
      },
      children: [
        Layout.scrollColumn(children: [
          Layout.row(children: [
            Display.statCard(
              label: 'This Month',
              format: 'currency',
              accent: true,
              source: 'month_total',
              valueKey: 'total',
            ),
            Display.statCard(
              label: 'Transactions',
              source: 'expense_count',
              valueKey: 'total',
            ),
          ]),
          Display.chart(
            chartType: 'pie',
            title: 'Spending by Category',
            source: 'by_category',
            groupBy: 'category',
            valueField: 'total',
          ),
          Display.entryList(
            title: 'Recent Expenses',
            source: 'recent',
            emptyState: Display.emptyState(
              message: 'No expenses logged yet',
              icon: 'receipt',
              action: Act.navigate('add_expense', label: 'Add your first expense'),
            ),
            itemLayout: Display.entryCard(
              title: '{{category_name}}',
              subtitle: '{{note}}',
              trailing: '{{amount}}',
              trailingFormat: 'currency',
              onTap: Act.navigate(
                'edit_expense',
                forwardFields: ['amount', 'category_id', 'date', 'note'],
                params: {},
              ),
            ),
          ),
        ]),
      ],
      fab: Actions.fab(
        icon: 'add',
        action: Act.navigate('add_expense', params: {}),
      ),
    ),

    // ═══════════════════════════════════════════
    //  EXPENSES — Full list
    // ═══════════════════════════════════════════
    'expenses': Layout.screen(
      appBar: Layout.appBar(title: 'Expenses', showBack: false),
      queries: {
        'all_expenses': Query.def(
          'SELECT e.id, e.amount, e.date, e.note, '
          'c.name as category_name '
          'FROM "m_expenses" e '
          'JOIN "m_expense_categories" c ON e.category_id = c.id '
          'ORDER BY e.date DESC',
        ),
      },
      mutations: {
        'delete': Mut.sql('DELETE FROM "m_expenses" WHERE id = :id'),
      },
      children: [
        Display.entryList(
          source: 'all_expenses',
          emptyState: Display.emptyState(
            message: 'No expenses yet',
            icon: 'receipt',
            action: Act.navigate('add_expense', label: 'Add an expense'),
          ),
          itemLayout: Display.entryCard(
            title: '{{category_name}}',
            subtitle: '{{note}}',
            trailing: '{{amount}}',
            trailingFormat: 'currency',
            onTap: Act.navigate(
              'edit_expense',
              forwardFields: ['amount', 'category_id', 'date', 'note'],
              params: {},
            ),
            swipeActions: {
              'right': Act.confirm(
                title: 'Delete Expense',
                message: 'Remove this expense?',
                onConfirm: Act.deleteEntry(),
              ),
            },
          ),
        ),
      ],
      fab: Actions.fab(
        icon: 'add',
        action: Act.navigate('add_expense', params: {}),
      ),
    ),

    // ═══════════════════════════════════════════
    //  CATEGORIES — Manage custom categories
    // ═══════════════════════════════════════════
    'categories': Layout.screen(
      appBar: Layout.appBar(title: 'Categories', showBack: false),
      queries: {
        'all_categories': Query.def(
          'SELECT c.id, c.name, c.icon, c.color, c.sort_order, '
          '(SELECT COUNT(*) FROM "m_expenses" e WHERE e.category_id = c.id) as expense_count '
          'FROM "m_expense_categories" c '
          'ORDER BY c.sort_order ASC',
        ),
      },
      mutations: {
        'delete':
            Mut.sql('DELETE FROM "m_expense_categories" WHERE id = :id'),
      },
      children: [
        Display.entryList(
          source: 'all_categories',
          emptyState: Display.emptyState(
            message: 'No categories',
            icon: 'tag',
            action: Act.navigate('add_category', label: 'Create a category'),
          ),
          itemLayout: Display.entryCard(
            title: '{{name}}',
            subtitle: '{{expense_count}} expenses',
            onTap: Act.navigate(
              'edit_category',
              forwardFields: ['name', 'icon', 'color', 'sort_order'],
              params: {},
            ),
            swipeActions: {
              'right': Act.confirm(
                title: 'Delete Category',
                message:
                    'Delete this category? Expenses using it will need to be re-categorized.',
                onConfirm: Act.deleteEntry(),
              ),
            },
          ),
        ),
      ],
      fab: Actions.fab(
        icon: 'add',
        action: Act.navigate('add_category', params: {}),
      ),
    ),

    // ═══════════════════════════════════════════
    //  ADD EXPENSE
    // ═══════════════════════════════════════════
    'add_expense': Layout.formScreen(
      title: 'New Expense',
      submitLabel: 'Save Expense',
      queries: {
        'available_categories': Query.def(
          'SELECT id, name FROM "m_expense_categories" ORDER BY sort_order ASC',
        ),
      },
      mutations: {
        'create': Mut.sql(
          'INSERT INTO "m_expenses" '
          '(id, amount, category_id, date, note, created_at, updated_at) '
          'VALUES (:id, :amount, :category_id, :date, :note, :created_at, :updated_at)',
        ),
      },
      children: [
        Inputs.currencyInput(
          fieldKey: 'amount',
          label: 'Amount',
          required: true,
          min: 0.01,
          validation: {
            'required': true,
            'min': 0.01,
            'message': 'Enter a valid amount',
          },
        ),
        Inputs.referencePicker(
          fieldKey: 'category_id',
          schemaKey: 'category',
          displayField: 'name',
          source: 'available_categories',
          label: 'Category',
          required: true,
          emptyLabel: 'No categories yet',
          emptyAction: Act.navigate('add_category', params: {}),
        ),
        Inputs.datePicker(
          fieldKey: 'date',
          label: 'Date',
          required: true,
        ),
        Inputs.textInput(
          fieldKey: 'note',
          label: 'Note',
        ),
      ],
    ),

    // ═══════════════════════════════════════════
    //  EDIT EXPENSE
    // ═══════════════════════════════════════════
    'edit_expense': Layout.formScreen(
      title: 'Edit Expense',
      editLabel: 'Update',
      queries: {
        'available_categories': Query.def(
          'SELECT id, name FROM "m_expense_categories" ORDER BY sort_order ASC',
        ),
      },
      mutations: {
        'update': Mut.sql(
          'UPDATE "m_expenses" SET '
          'amount = COALESCE(:amount, amount), '
          'category_id = COALESCE(:category_id, category_id), '
          'date = COALESCE(:date, date), '
          'note = COALESCE(:note, note), '
          'updated_at = :updated_at '
          'WHERE id = :id',
        ),
      },
      children: [
        Inputs.currencyInput(
          fieldKey: 'amount',
          label: 'Amount',
          required: true,
          min: 0.01,
          validation: {
            'required': true,
            'min': 0.01,
            'message': 'Enter a valid amount',
          },
        ),
        Inputs.referencePicker(
          fieldKey: 'category_id',
          schemaKey: 'category',
          displayField: 'name',
          source: 'available_categories',
          label: 'Category',
          required: true,
          emptyLabel: 'No categories yet',
          emptyAction: Act.navigate('add_category', params: {}),
        ),
        Inputs.datePicker(
          fieldKey: 'date',
          label: 'Date',
          required: true,
        ),
        Inputs.textInput(
          fieldKey: 'note',
          label: 'Note',
        ),
      ],
    ),

    // ═══════════════════════════════════════════
    //  ADD CATEGORY
    // ═══════════════════════════════════════════
    'add_category': Layout.formScreen(
      title: 'New Category',
      submitLabel: 'Save Category',
      defaults: {'icon': 'tag', 'color': '#757575', 'sort_order': 99},
      mutations: {
        'create': Mut.sql(
          'INSERT INTO "m_expense_categories" '
          '(id, name, icon, color, sort_order, created_at, updated_at) '
          'VALUES (:id, :name, :icon, :color, :sort_order, :created_at, :updated_at)',
        ),
      },
      children: [
        Inputs.textInput(
          fieldKey: 'name',
          label: 'Category Name',
          required: true,
          validation: {
            'required': true,
            'minLength': 1,
            'message': 'Give your category a name',
          },
        ),
        Inputs.textInput(
          fieldKey: 'icon',
          label: 'Icon Name',
          defaultValue: 'tag',
        ),
        Inputs.colorPicker(
          fieldKey: 'color',
          label: 'Color',
        ),
      ],
    ),

    // ═══════════════════════════════════════════
    //  EDIT CATEGORY
    // ═══════════════════════════════════════════
    'edit_category': Layout.formScreen(
      title: 'Edit Category',
      editLabel: 'Update',
      mutations: {
        'update': Mut.sql(
          'UPDATE "m_expense_categories" SET '
          'name = COALESCE(:name, name), '
          'icon = COALESCE(:icon, icon), '
          'color = COALESCE(:color, color), '
          'sort_order = COALESCE(:sort_order, sort_order), '
          'updated_at = :updated_at '
          'WHERE id = :id',
        ),
      },
      children: [
        Inputs.textInput(
          fieldKey: 'name',
          label: 'Category Name',
          required: true,
          validation: {
            'required': true,
            'minLength': 1,
            'message': 'Give your category a name',
          },
        ),
        Inputs.textInput(
          fieldKey: 'icon',
          label: 'Icon Name',
        ),
        Inputs.colorPicker(
          fieldKey: 'color',
          label: 'Color',
        ),
      ],
    ),
  },
);
