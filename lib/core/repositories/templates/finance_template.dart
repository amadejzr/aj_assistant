import '../../../features/blueprint/dsl/blueprint_dsl.dart';

Json financeTemplate() => TemplateDef.build(
  name: 'Finance 2.0',
  description:
      'Accounts, budgets, categories, recurring transactions & insights',
  longDescription:
      'A comprehensive personal finance tracker. Manage multiple accounts '
      '(cash, bank, credit card), organize spending with two-tier categories '
      'and tags, set monthly budgets per category, and save recurring charges '
      'as quick-log templates. The dashboard gives you a monthly snapshot with '
      'spending breakdowns and cash-flow stats.',
  icon: 'wallet',
  color: '#1B5E20',
  category: 'Finance',
  tags: [
    'finance',
    'expenses',
    'budget',
    'accounts',
    'income',
    'recurring',
    'tracker',
  ],
  featured: true,
  sortOrder: 0,
  guide: [
    Guide.step(
      title: 'Add a Transaction',
      body: 'Tap + to log an expense or income. Pick an account, choose a '
          'category, and enter the amount. Account balances update automatically.',
    ),
    Guide.step(
      title: 'Set Budgets',
      body: 'Open a category and set a monthly budget. The Budgets tab tracks '
          'spending against each limit with progress bars.',
    ),
    Guide.step(
      title: 'Use Recurring Templates',
      body: 'Save recurring charges (rent, subscriptions) in the Recurring tab. '
          'Tap one to instantly pre-fill a new transaction — no retyping.',
    ),
    Guide.step(
      title: 'Explore the Dashboard',
      body: 'The Dashboard shows this month\'s spending, income, net cash flow, '
          'and a category breakdown chart. Tap the gear icon to manage categories '
          'and accounts.',
    ),
  ],

  // ─── Navigation ───
  navigation: Nav.bottomNav(items: [
    Nav.item(label: 'Dashboard', icon: 'chart-line-up', screenId: 'main'),
    Nav.item(
        label: 'Transactions', icon: 'list-bullets', screenId: 'transactions'),
    Nav.item(label: 'Budgets', icon: 'chart-bar', screenId: 'budgets'),
    Nav.item(
        label: 'Recurring',
        icon: 'arrows-clockwise',
        screenId: 'recurring'),
  ]),

  // ─── Database ───
  database: Db.build(
    tableNames: {
      'account': 'm_fin_accounts',
      'category': 'm_fin_categories',
      'tag': 'm_fin_tags',
      'transaction': 'm_fin_transactions',
      'split': 'm_fin_splits',
      'recurring': 'm_fin_recurring',
    },
    setup: [
      // ── Accounts ──
      '''CREATE TABLE IF NOT EXISTS "m_fin_accounts" (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            icon TEXT NOT NULL DEFAULT 'wallet',
            color TEXT NOT NULL DEFAULT '#757575',
            balance REAL NOT NULL DEFAULT 0,
            sort_order INTEGER NOT NULL DEFAULT 0,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )''',

      // ── Categories ──
      '''CREATE TABLE IF NOT EXISTS "m_fin_categories" (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            icon TEXT NOT NULL DEFAULT 'tag',
            color TEXT NOT NULL DEFAULT '#757575',
            budget_amount REAL NOT NULL DEFAULT 0,
            sort_order INTEGER NOT NULL DEFAULT 0,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )''',

      // ── Tags ──
      '''CREATE TABLE IF NOT EXISTS "m_fin_tags" (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            category_id TEXT NOT NULL REFERENCES "m_fin_categories"(id),
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )''',

      // ── Transactions ──
      '''CREATE TABLE IF NOT EXISTS "m_fin_transactions" (
            id TEXT PRIMARY KEY,
            amount REAL NOT NULL,
            type TEXT NOT NULL DEFAULT 'expense',
            merchant TEXT,
            category_id TEXT REFERENCES "m_fin_categories"(id),
            tag_id TEXT REFERENCES "m_fin_tags"(id),
            account_id TEXT NOT NULL REFERENCES "m_fin_accounts"(id),
            date INTEGER NOT NULL,
            note TEXT,
            is_split INTEGER NOT NULL DEFAULT 0,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )''',

      // ── Splits ──
      '''CREATE TABLE IF NOT EXISTS "m_fin_splits" (
            id TEXT PRIMARY KEY,
            transaction_id TEXT NOT NULL REFERENCES "m_fin_transactions"(id),
            category_id TEXT NOT NULL REFERENCES "m_fin_categories"(id),
            amount REAL NOT NULL,
            note TEXT,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )''',

      // ── Recurring ──
      '''CREATE TABLE IF NOT EXISTS "m_fin_recurring" (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            amount REAL NOT NULL,
            type TEXT NOT NULL DEFAULT 'expense',
            merchant TEXT,
            category_id TEXT REFERENCES "m_fin_categories"(id),
            account_id TEXT REFERENCES "m_fin_accounts"(id),
            frequency TEXT NOT NULL DEFAULT 'monthly',
            next_date INTEGER,
            is_active INTEGER NOT NULL DEFAULT 1,
            note TEXT,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )''',

      // ── Indexes ──
      'CREATE INDEX IF NOT EXISTS "idx_fin_txn_date" ON "m_fin_transactions" (date)',
      'CREATE INDEX IF NOT EXISTS "idx_fin_txn_cat" ON "m_fin_transactions" (category_id)',
      'CREATE INDEX IF NOT EXISTS "idx_fin_txn_acct" ON "m_fin_transactions" (account_id)',
      'CREATE INDEX IF NOT EXISTS "idx_fin_txn_type" ON "m_fin_transactions" (type)',
      'CREATE INDEX IF NOT EXISTS "idx_fin_splits_txn" ON "m_fin_splits" (transaction_id)',
      'CREATE INDEX IF NOT EXISTS "idx_fin_tags_cat" ON "m_fin_tags" (category_id)',
      'CREATE INDEX IF NOT EXISTS "idx_fin_rec_active" ON "m_fin_recurring" (is_active, next_date)',
      'CREATE INDEX IF NOT EXISTS "idx_fin_cat_sort" ON "m_fin_categories" (sort_order)',
      'CREATE INDEX IF NOT EXISTS "idx_fin_acct_sort" ON "m_fin_accounts" (sort_order)',

      // ── Triggers ──

      // 1. After INSERT on transactions: adjust account balance
      '''CREATE TRIGGER IF NOT EXISTS "trg_fin_txn_add"
            AFTER INSERT ON "m_fin_transactions"
            FOR EACH ROW BEGIN
              UPDATE "m_fin_accounts"
              SET balance = CASE
                WHEN NEW.type = 'income' THEN balance + NEW.amount
                ELSE balance - NEW.amount
              END
              WHERE id = NEW.account_id;
            END''',

      // 2. After DELETE on transactions: reverse balance change
      '''CREATE TRIGGER IF NOT EXISTS "trg_fin_txn_remove"
            AFTER DELETE ON "m_fin_transactions"
            FOR EACH ROW BEGIN
              UPDATE "m_fin_accounts"
              SET balance = CASE
                WHEN OLD.type = 'income' THEN balance - OLD.amount
                ELSE balance + OLD.amount
              END
              WHERE id = OLD.account_id;
            END''',

      // 3. After UPDATE of amount/type on transactions: adjust by difference
      '''CREATE TRIGGER IF NOT EXISTS "trg_fin_txn_adjust"
            AFTER UPDATE OF amount, type, account_id ON "m_fin_transactions"
            FOR EACH ROW BEGIN
              UPDATE "m_fin_accounts"
              SET balance = CASE
                WHEN OLD.type = 'income' THEN balance - OLD.amount
                ELSE balance + OLD.amount
              END
              WHERE id = OLD.account_id;
              UPDATE "m_fin_accounts"
              SET balance = CASE
                WHEN NEW.type = 'income' THEN balance + NEW.amount
                ELSE balance - NEW.amount
              END
              WHERE id = NEW.account_id;
            END''',

      // 4. Before DELETE on transactions: cascade delete splits
      '''CREATE TRIGGER IF NOT EXISTS "trg_fin_splits_cascade"
            BEFORE DELETE ON "m_fin_transactions"
            FOR EACH ROW BEGIN
              DELETE FROM "m_fin_splits" WHERE transaction_id = OLD.id;
            END''',

      // 5. Before DELETE on categories: cascade delete tags
      '''CREATE TRIGGER IF NOT EXISTS "trg_fin_tags_cascade"
            BEFORE DELETE ON "m_fin_categories"
            FOR EACH ROW BEGIN
              DELETE FROM "m_fin_tags" WHERE category_id = OLD.id;
            END''',

      // 6. Before DELETE on categories: nullify category_id on transactions
      '''CREATE TRIGGER IF NOT EXISTS "trg_fin_txn_cat_cascade"
            BEFORE DELETE ON "m_fin_categories"
            FOR EACH ROW BEGIN
              UPDATE "m_fin_transactions" SET category_id = NULL WHERE category_id = OLD.id;
            END''',

      // ── Seed: Accounts ──
      '''INSERT OR IGNORE INTO "m_fin_accounts"
            (id, name, icon, color, balance, sort_order, created_at, updated_at) VALUES
            ('acct_cash',   'Cash',          'money',       '#4CAF50', 0, 1, strftime('%s','now')*1000, strftime('%s','now')*1000),
            ('acct_bank',   'Bank Account',  'bank',        '#2196F3', 0, 2, strftime('%s','now')*1000, strftime('%s','now')*1000),
            ('acct_credit', 'Credit Card',   'credit-card', '#F44336', 0, 3, strftime('%s','now')*1000, strftime('%s','now')*1000)''',

      // ── Seed: Categories ──
      '''INSERT OR IGNORE INTO "m_fin_categories"
            (id, name, icon, color, budget_amount, sort_order, created_at, updated_at) VALUES
            ('fcat_housing',       'Housing',        'house',        '#795548',  0, 1, strftime('%s','now')*1000, strftime('%s','now')*1000),
            ('fcat_transport',     'Transport',      'car',          '#2196F3',  0, 2, strftime('%s','now')*1000, strftime('%s','now')*1000),
            ('fcat_food',          'Food & Drink',   'fork-knife',   '#4CAF50',  0, 3, strftime('%s','now')*1000, strftime('%s','now')*1000),
            ('fcat_entertainment', 'Entertainment',  'ticket',       '#9C27B0',  0, 4, strftime('%s','now')*1000, strftime('%s','now')*1000),
            ('fcat_utilities',     'Utilities',      'lightning',    '#FF9800',  0, 5, strftime('%s','now')*1000, strftime('%s','now')*1000),
            ('fcat_shopping',      'Shopping',       'shopping-bag', '#E91E63',  0, 6, strftime('%s','now')*1000, strftime('%s','now')*1000),
            ('fcat_health',        'Health',         'heartbeat',    '#00BCD4',  0, 7, strftime('%s','now')*1000, strftime('%s','now')*1000),
            ('fcat_income',        'Income',         'arrow-down',   '#43A047',  0, 8, strftime('%s','now')*1000, strftime('%s','now')*1000),
            ('fcat_other',         'Other',          'dots-three',   '#757575',  0, 9, strftime('%s','now')*1000, strftime('%s','now')*1000)''',
    ],
    teardown: [
      'DROP TABLE IF EXISTS "m_fin_splits"',
      'DROP TABLE IF EXISTS "m_fin_recurring"',
      'DROP TABLE IF EXISTS "m_fin_transactions"',
      'DROP TABLE IF EXISTS "m_fin_tags"',
      'DROP TABLE IF EXISTS "m_fin_categories"',
      'DROP TABLE IF EXISTS "m_fin_accounts"',
    ],
  ),

  // ─── Screens ───
  screens: {
    // ═══════════════════════════════════════════
    //  DASHBOARD
    // ═══════════════════════════════════════════
    'main': Layout.screen(
      appBar: Layout.appBar(
        title: 'Finance 2.0',
        showBack: false,
      ),
      queries: {
        'month_spent': Query.def(
          'SELECT COALESCE(SUM(amount), 0) as total '
          'FROM "m_fin_transactions" '
          "WHERE type = 'expense' "
          "AND date >= strftime('%s', date('now', 'start of month')) * 1000",
        ),
        'month_income': Query.def(
          'SELECT COALESCE(SUM(amount), 0) as total '
          'FROM "m_fin_transactions" '
          "WHERE type = 'income' "
          "AND date >= strftime('%s', date('now', 'start of month')) * 1000",
        ),
        'net_flow': Query.def(
          'SELECT '
          "COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END), 0) - "
          "COALESCE(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END), 0) "
          'as total '
          'FROM "m_fin_transactions" '
          "WHERE date >= strftime('%s', date('now', 'start of month')) * 1000",
        ),
        'by_category': Query.def(
          'SELECT c.name as category, COALESCE(SUM(t.amount), 0) as total '
          'FROM "m_fin_transactions" t '
          'JOIN "m_fin_categories" c ON t.category_id = c.id '
          "WHERE t.type = 'expense' "
          "AND t.date >= strftime('%s', date('now', 'start of month')) * 1000 "
          'GROUP BY c.name ORDER BY total DESC',
        ),
        'recent': Query.def(
          'SELECT t.id, t.amount, t.type, t.merchant, t.date, t.note, '
          't.category_id, t.tag_id, t.account_id, t.is_split, '
          'c.name as category_name, a.name as account_name '
          'FROM "m_fin_transactions" t '
          'LEFT JOIN "m_fin_categories" c ON t.category_id = c.id '
          'JOIN "m_fin_accounts" a ON t.account_id = a.id '
          'ORDER BY t.date DESC LIMIT 5',
        ),
      },
      children: [
        Layout.scrollColumn(children: [
          Layout.row(children: [
            Display.statCard(
              label: 'Spent',
              format: 'currency',
              accent: true,
              source: 'month_spent',
              valueKey: 'total',
            ),
            Display.statCard(
              label: 'Income',
              format: 'currency',
              source: 'month_income',
              valueKey: 'total',
            ),
          ]),
          Layout.row(children: [
            Display.statCard(
              label: 'Net Cash Flow',
              format: 'currency',
              source: 'net_flow',
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
            title: 'Recent Transactions',
            source: 'recent',
            emptyState: Display.emptyState(
              message: 'No transactions yet',
              icon: 'wallet',
              action: Act.navigate('add_transaction',
                  label: 'Add your first transaction'),
            ),
            itemLayout: Display.entryCard(
              title: '{{merchant}}',
              subtitle: '{{category_name}}',
              trailing: '{{amount}}',
              trailingFormat: 'currency',
              onTap: Act.navigate(
                'view_transaction',
                forwardFields: [
                  'amount', 'type', 'merchant', 'category_id', 'tag_id',
                  'account_id', 'date', 'note', 'is_split',
                  'category_name', 'account_name',
                ],
                params: {},
              ),
            ),
          ),
        ]),
      ],
      fab: Actions.fab(
        icon: 'add',
        action: Act.navigate('add_transaction', params: {}),
      ),
      appBarActions: [
        Actions.actionMenu(
          icon: 'gear-six',
          items: [
            Actions.menuItem(
              label: 'Categories',
              icon: 'tag',
              action: Act.navigate('categories', params: {}),
            ),
            Actions.menuItem(
              label: 'Accounts',
              icon: 'wallet',
              action: Act.navigate('accounts', params: {}),
            ),
          ],
        ),
      ],
    ),

    // ═══════════════════════════════════════════
    //  TRANSACTIONS — Full list
    // ═══════════════════════════════════════════
    'transactions': Layout.screen(
      appBar: Layout.appBar(title: 'Transactions', showBack: false),
      queries: {
        'all_transactions': Query.def(
          'SELECT t.id, t.amount, t.type, t.merchant, t.date, t.note, '
          't.category_id, t.tag_id, t.account_id, t.is_split, '
          'c.name as category_name, a.name as account_name '
          'FROM "m_fin_transactions" t '
          'LEFT JOIN "m_fin_categories" c ON t.category_id = c.id '
          'JOIN "m_fin_accounts" a ON t.account_id = a.id '
          'ORDER BY t.date DESC',
        ),
      },
      mutations: {
        'delete': Mut.sql('DELETE FROM "m_fin_transactions" WHERE id = :id'),
      },
      children: [
        Display.entryList(
          source: 'all_transactions',
          emptyState: Display.emptyState(
            message: 'No transactions yet',
            icon: 'list-bullets',
            action:
                Act.navigate('add_transaction', label: 'Add a transaction'),
          ),
          itemLayout: Display.entryCard(
            title: '{{merchant}}',
            subtitle: '{{category_name}}',
            trailing: '{{amount}}',
            trailingFormat: 'currency',
            onTap: Act.navigate(
              'view_transaction',
              forwardFields: [
                'amount', 'type', 'merchant', 'category_id', 'tag_id',
                'account_id', 'date', 'note', 'is_split',
                'category_name', 'account_name',
              ],
              params: {},
            ),
            swipeActions: {
              'right': Act.confirm(
                title: 'Delete Transaction',
                message: 'Remove this transaction? Account balance will be adjusted.',
                onConfirm: Act.deleteEntry(),
              ),
            },
          ),
        ),
      ],
      fab: Actions.fab(
        icon: 'add',
        action: Act.navigate('add_transaction', params: {}),
      ),
    ),

    // ═══════════════════════════════════════════
    //  BUDGETS — Overview
    // ═══════════════════════════════════════════
    'budgets': Layout.screen(
      appBar: Layout.appBar(title: 'Budgets', showBack: false),
      queries: {
        'total_budget': Query.def(
          'SELECT COALESCE(SUM(budget_amount), 0) as total '
          'FROM "m_fin_categories" WHERE budget_amount > 0',
        ),
        'total_spent': Query.def(
          'SELECT COALESCE(SUM(amount), 0) as total '
          'FROM "m_fin_transactions" '
          "WHERE type = 'expense' "
          "AND date >= strftime('%s', date('now', 'start of month')) * 1000",
        ),
        'budget_remaining': Query.def(
          'SELECT '
          'COALESCE(SUM(c.budget_amount), 0) - '
          "COALESCE((SELECT SUM(t.amount) FROM \"m_fin_transactions\" t WHERE t.type = 'expense' AND t.date >= strftime('%s', date('now', 'start of month')) * 1000), 0) "
          'as total '
          'FROM "m_fin_categories" c WHERE c.budget_amount > 0',
        ),
        'budget_categories': Query.def(
          'SELECT c.id, c.name, c.icon, c.color, c.budget_amount, '
          "COALESCE((SELECT SUM(t.amount) FROM \"m_fin_transactions\" t WHERE t.category_id = c.id AND t.type = 'expense' AND t.date >= strftime('%s', date('now', 'start of month')) * 1000), 0) as spent "
          'FROM "m_fin_categories" c '
          'WHERE c.budget_amount > 0 '
          'ORDER BY c.sort_order ASC',
        ),
      },
      children: [
        Layout.scrollColumn(children: [
          Layout.row(children: [
            Display.statCard(
              label: 'Total Budget',
              format: 'currency',
              source: 'total_budget',
              valueKey: 'total',
            ),
            Display.statCard(
              label: 'Total Spent',
              format: 'currency',
              accent: true,
              source: 'total_spent',
              valueKey: 'total',
            ),
          ]),
          Layout.row(children: [
            Display.statCard(
              label: 'Remaining',
              format: 'currency',
              source: 'budget_remaining',
              valueKey: 'total',
            ),
          ]),
          Display.entryList(
            title: 'Budget by Category',
            source: 'budget_categories',
            emptyState: Display.emptyState(
              message: 'No budgets set',
              icon: 'chart-bar',
              action: Act.navigate('categories',
                  label: 'Set budgets on your categories'),
            ),
            itemLayout: Display.entryCard(
              title: '{{name}}',
              subtitle: r'${{spent}} / ${{budget_amount}}',
              onTap: Act.navigate(
                'budget_detail',
                forwardFields: ['name', 'icon', 'color', 'budget_amount', 'spent'],
                params: {},
              ),
            ),
          ),
        ]),
      ],
    ),

    // ═══════════════════════════════════════════
    //  BUDGET DETAIL — Per-category view
    // ═══════════════════════════════════════════
    'budget_detail': Layout.screen(
      appBar: Layout.appBar(title: '{{name}} Budget'),
      queries: {
        'cat_transactions': Query.def(
          'SELECT t.id, t.amount, t.merchant, t.date, t.note, '
          'a.name as account_name '
          'FROM "m_fin_transactions" t '
          'JOIN "m_fin_accounts" a ON t.account_id = a.id '
          "WHERE t.category_id = :id AND t.type = 'expense' "
          "AND t.date >= strftime('%s', date('now', 'start of month')) * 1000 "
          'ORDER BY t.date DESC',
          params: {'id': '{{_entryId}}'},
        ),
      },
      children: [
        Layout.scrollColumn(children: [
          Display.progressBar(
            label: 'Spent',
            value: '{{spent}}',
            max: '{{budget_amount}}',
            showPercentage: true,
          ),
          Layout.row(children: [
            Display.statCard(
              label: 'Budget',
              format: 'currency',
              value: '{{budget_amount}}',
            ),
            Display.statCard(
              label: 'Spent',
              format: 'currency',
              accent: true,
              value: '{{spent}}',
            ),
          ]),
          Display.entryList(
            title: 'Transactions This Month',
            source: 'cat_transactions',
            emptyState: Display.emptyState(
              message: 'No spending in this category yet',
              icon: 'chart-bar',
            ),
            itemLayout: Display.entryCard(
              title: '{{merchant}}',
              subtitle: '{{account_name}}',
              trailing: '{{amount}}',
              trailingFormat: 'currency',
            ),
          ),
        ]),
      ],
    ),

    // ═══════════════════════════════════════════
    //  RECURRING — Templates list
    // ═══════════════════════════════════════════
    'recurring': Layout.screen(
      appBar: Layout.appBar(title: 'Recurring', showBack: false),
      queries: {
        'active_recurring': Query.def(
          'SELECT r.id, r.name, r.amount, r.type, r.merchant, '
          'r.category_id, r.account_id, r.frequency, r.next_date, '
          'r.note, r.is_active, '
          'c.name as category_name, a.name as account_name '
          'FROM "m_fin_recurring" r '
          'LEFT JOIN "m_fin_categories" c ON r.category_id = c.id '
          'LEFT JOIN "m_fin_accounts" a ON r.account_id = a.id '
          'WHERE r.is_active = 1 '
          'ORDER BY r.next_date ASC',
        ),
      },
      mutations: {
        'delete': Mut.sql('DELETE FROM "m_fin_recurring" WHERE id = :id'),
      },
      children: [
        Display.entryList(
          source: 'active_recurring',
          emptyState: Display.emptyState(
            message: 'No recurring items',
            icon: 'arrows-clockwise',
            action: Act.navigate('add_recurring',
                label: 'Add a recurring charge'),
          ),
          itemLayout: Display.entryCard(
            title: '{{name}}',
            subtitle: '{{frequency}} \u00B7 {{category_name}}',
            trailing: '{{amount}}',
            trailingFormat: 'currency',
            onTap: Act.navigate(
              'add_transaction',
              forwardFields: [
                'amount', 'type', 'merchant', 'category_id', 'account_id',
              ],
              params: {},
            ),
            swipeActions: {
              'right': Act.confirm(
                title: 'Delete Recurring',
                message: 'Remove this recurring template?',
                onConfirm: Act.deleteEntry(),
              ),
            },
          ),
        ),
      ],
      appBarActions: [
        Actions.iconButton(
          icon: 'plus',
          action: Act.navigate('add_recurring', params: {}),
        ),
      ],
    ),

    // ═══════════════════════════════════════════
    //  ADD TRANSACTION
    // ═══════════════════════════════════════════
    'add_transaction': Layout.formScreen(
      title: 'New Transaction',
      submitLabel: 'Save Transaction',
      defaults: {'type': 'expense'},
      queries: {
        'available_categories': Query.def(
          'SELECT id, name FROM "m_fin_categories" ORDER BY sort_order ASC',
        ),
        'available_tags': Query.def(
          'SELECT id, name FROM "m_fin_tags" ORDER BY name ASC',
        ),
        'available_accounts': Query.def(
          'SELECT id, name FROM "m_fin_accounts" ORDER BY sort_order ASC',
        ),
      },
      mutations: {
        'create': Mut.sql(
          'INSERT INTO "m_fin_transactions" '
          '(id, amount, type, merchant, category_id, tag_id, account_id, date, note, is_split, created_at, updated_at) '
          'VALUES (:id, :amount, :type, :merchant, :category_id, :tag_id, :account_id, :date, :note, 0, :created_at, :updated_at)',
        ),
      },
      children: [
        Inputs.enumSelector(
          fieldKey: 'type',
          label: 'Type',
          options: ['expense', 'income'],
          required: true,
        ),
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
        Inputs.textInput(
          fieldKey: 'merchant',
          label: 'Merchant',
        ),
        Inputs.referencePicker(
          fieldKey: 'category_id',
          schemaKey: 'category',
          displayField: 'name',
          source: 'available_categories',
          label: 'Category',
          emptyLabel: 'No categories yet',
          emptyAction: Act.navigate('add_category', params: {}),
        ),
        Inputs.referencePicker(
          fieldKey: 'tag_id',
          schemaKey: 'tag',
          displayField: 'name',
          source: 'available_tags',
          label: 'Tag',
          emptyLabel: 'No tags yet',
          emptyAction: Act.navigate('add_tag', params: {}),
        ),
        Inputs.referencePicker(
          fieldKey: 'account_id',
          schemaKey: 'account',
          displayField: 'name',
          source: 'available_accounts',
          label: 'Account',
          required: true,
          emptyLabel: 'No accounts yet',
          emptyAction: Act.navigate('add_account', params: {}),
        ),
        Inputs.datePicker(
          fieldKey: 'date',
          label: 'Date',
          required: true,
        ),
        Inputs.textInput(
          fieldKey: 'note',
          label: 'Note',
          multiline: true,
        ),
      ],
    ),

    // ═══════════════════════════════════════════
    //  EDIT TRANSACTION
    // ═══════════════════════════════════════════
    'edit_transaction': Layout.formScreen(
      title: 'Edit Transaction',
      editLabel: 'Update',
      queries: {
        'available_categories': Query.def(
          'SELECT id, name FROM "m_fin_categories" ORDER BY sort_order ASC',
        ),
        'available_tags': Query.def(
          'SELECT id, name FROM "m_fin_tags" ORDER BY name ASC',
        ),
        'available_accounts': Query.def(
          'SELECT id, name FROM "m_fin_accounts" ORDER BY sort_order ASC',
        ),
      },
      mutations: {
        'update': Mut.sql(
          'UPDATE "m_fin_transactions" SET '
          'amount = COALESCE(:amount, amount), '
          'type = COALESCE(:type, type), '
          'merchant = COALESCE(:merchant, merchant), '
          'category_id = COALESCE(:category_id, category_id), '
          'tag_id = COALESCE(:tag_id, tag_id), '
          'account_id = COALESCE(:account_id, account_id), '
          'date = COALESCE(:date, date), '
          'note = COALESCE(:note, note), '
          'updated_at = :updated_at '
          'WHERE id = :id',
        ),
      },
      children: [
        Inputs.enumSelector(
          fieldKey: 'type',
          label: 'Type',
          options: ['expense', 'income'],
          required: true,
        ),
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
        Inputs.textInput(
          fieldKey: 'merchant',
          label: 'Merchant',
        ),
        Inputs.referencePicker(
          fieldKey: 'category_id',
          schemaKey: 'category',
          displayField: 'name',
          source: 'available_categories',
          label: 'Category',
          emptyLabel: 'No categories yet',
          emptyAction: Act.navigate('add_category', params: {}),
        ),
        Inputs.referencePicker(
          fieldKey: 'tag_id',
          schemaKey: 'tag',
          displayField: 'name',
          source: 'available_tags',
          label: 'Tag',
          emptyLabel: 'No tags yet',
          emptyAction: Act.navigate('add_tag', params: {}),
        ),
        Inputs.referencePicker(
          fieldKey: 'account_id',
          schemaKey: 'account',
          displayField: 'name',
          source: 'available_accounts',
          label: 'Account',
          required: true,
          emptyLabel: 'No accounts yet',
          emptyAction: Act.navigate('add_account', params: {}),
        ),
        Inputs.datePicker(
          fieldKey: 'date',
          label: 'Date',
          required: true,
        ),
        Inputs.textInput(
          fieldKey: 'note',
          label: 'Note',
          multiline: true,
        ),
      ],
    ),

    // ═══════════════════════════════════════════
    //  VIEW TRANSACTION — Detail view
    // ═══════════════════════════════════════════
    'view_transaction': Layout.screen(
      appBar: Layout.appBar(title: '{{merchant}}'),
      queries: {
        'splits': Query.def(
          'SELECT s.id, s.amount, s.note, '
          'c.name as category_name '
          'FROM "m_fin_splits" s '
          'JOIN "m_fin_categories" c ON s.category_id = c.id '
          'WHERE s.transaction_id = :id '
          'ORDER BY s.created_at ASC',
          params: {'id': '{{_entryId}}'},
        ),
      },
      mutations: {
        'delete': Mut.sql('DELETE FROM "m_fin_transactions" WHERE id = :id'),
      },
      children: [
        Layout.scrollColumn(children: [
          Layout.row(children: [
            Display.statCard(
              label: 'Amount',
              format: 'currency',
              accent: true,
              value: '{{amount}}',
            ),
            Display.statCard(
              label: 'Type',
              value: '{{type}}',
            ),
          ]),
          Layout.section(
            title: 'Details',
            children: [
              Display.textDisplay(label: 'Merchant', value: '{{merchant}}'),
              Display.textDisplay(
                  label: 'Category', value: '{{category_name}}'),
              Display.textDisplay(
                  label: 'Account', value: '{{account_name}}'),
              Display.textDisplay(label: 'Date', value: '{{date}}'),
              Display.textDisplay(label: 'Note', value: '{{note}}'),
            ],
          ),
          Layout.conditional(
            condition: {'field': 'is_split', 'op': '==', 'value': 1},
            thenChildren: [
              Display.entryList(
                title: 'Splits',
                source: 'splits',
                itemLayout: Display.entryCard(
                  title: '{{category_name}}',
                  subtitle: '{{note}}',
                  trailing: '{{amount}}',
                  trailingFormat: 'currency',
                ),
              ),
            ],
          ),
        ]),
      ],
      appBarActions: [
        Actions.iconButton(
          icon: 'pencil',
          action: Act.navigate(
            'edit_transaction',
            forwardFields: [
              'amount', 'type', 'merchant', 'category_id', 'tag_id',
              'account_id', 'date', 'note',
            ],
            params: {},
          ),
        ),
        Actions.iconButton(
          icon: 'trash',
          action: Act.confirm(
            title: 'Delete Transaction',
            message:
                'Delete this transaction? Account balance will be adjusted.',
            onConfirm: Act.deleteEntry(),
          ),
        ),
      ],
      fab: Actions.fab(
        icon: 'plus',
        action: Act.navigate('add_split', params: {}),
        // visible: {'field': 'is_split', 'op': '==', 'value': 1},
      ),
    ),

    // ═══════════════════════════════════════════
    //  ADD SPLIT
    // ═══════════════════════════════════════════
    'add_split': Layout.formScreen(
      title: 'Add Split',
      submitLabel: 'Save Split',
      queries: {
        'available_categories': Query.def(
          'SELECT id, name FROM "m_fin_categories" ORDER BY sort_order ASC',
        ),
      },
      mutations: {
        'create': Mut.sql(
          'INSERT INTO "m_fin_splits" '
          '(id, transaction_id, category_id, amount, note, created_at, updated_at) '
          'VALUES (:id, :_parentId, :category_id, :amount, :note, :created_at, :updated_at)',
        ),
      },
      children: [
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
        Inputs.textInput(
          fieldKey: 'note',
          label: 'Note',
        ),
      ],
    ),

    // ═══════════════════════════════════════════
    //  CATEGORIES — List
    // ═══════════════════════════════════════════
    'categories': Layout.screen(
      appBar: Layout.appBar(title: 'Categories'),
      queries: {
        'all_categories': Query.def(
          'SELECT c.id, c.name, c.icon, c.color, c.budget_amount, c.sort_order, '
          '(SELECT COUNT(*) FROM "m_fin_transactions" t WHERE t.category_id = c.id) as txn_count '
          'FROM "m_fin_categories" c '
          'ORDER BY c.sort_order ASC',
        ),
      },
      mutations: {
        'delete': Mut.sql('DELETE FROM "m_fin_categories" WHERE id = :id'),
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
            subtitle: '{{txn_count}} transactions',
            onTap: Act.navigate(
              'edit_category',
              forwardFields: [
                'name', 'icon', 'color', 'budget_amount', 'sort_order',
              ],
              params: {},
            ),
            swipeActions: {
              'right': Act.confirm(
                title: 'Delete Category',
                message:
                    'Delete this category? Tags will be removed and transactions un-categorized.',
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
    //  ADD CATEGORY
    // ═══════════════════════════════════════════
    'add_category': Layout.formScreen(
      title: 'New Category',
      submitLabel: 'Save Category',
      defaults: {'icon': 'tag', 'color': '#757575', 'sort_order': 99},
      mutations: {
        'create': Mut.sql(
          'INSERT INTO "m_fin_categories" '
          '(id, name, icon, color, budget_amount, sort_order, created_at, updated_at) '
          'VALUES (:id, :name, :icon, :color, COALESCE(:budget_amount, 0), :sort_order, :created_at, :updated_at)',
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
        Inputs.colorPicker(
          fieldKey: 'color',
          label: 'Color',
        ),
        Inputs.currencyInput(
          fieldKey: 'budget_amount',
          label: 'Monthly Budget',
          min: 0,
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
          'UPDATE "m_fin_categories" SET '
          'name = COALESCE(:name, name), '
          'color = COALESCE(:color, color), '
          'budget_amount = COALESCE(:budget_amount, budget_amount), '
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
        Inputs.colorPicker(
          fieldKey: 'color',
          label: 'Color',
        ),
        Inputs.currencyInput(
          fieldKey: 'budget_amount',
          label: 'Monthly Budget',
          min: 0,
        ),
      ],
    ),

    // ═══════════════════════════════════════════
    //  ACCOUNTS — List
    // ═══════════════════════════════════════════
    'accounts': Layout.screen(
      appBar: Layout.appBar(title: 'Accounts'),
      queries: {
        'all_accounts': Query.def(
          'SELECT id, name, icon, color, balance, sort_order '
          'FROM "m_fin_accounts" '
          'ORDER BY sort_order ASC',
        ),
      },
      mutations: {
        'delete': Mut.sql('DELETE FROM "m_fin_accounts" WHERE id = :id'),
      },
      children: [
        Display.entryList(
          source: 'all_accounts',
          emptyState: Display.emptyState(
            message: 'No accounts',
            icon: 'wallet',
            action: Act.navigate('add_account', label: 'Add an account'),
          ),
          itemLayout: Display.entryCard(
            title: '{{name}}',
            trailing: '{{balance}}',
            trailingFormat: 'currency',
            onTap: Act.navigate(
              'edit_account',
              forwardFields: ['name', 'icon', 'color', 'balance', 'sort_order'],
              params: {},
            ),
            swipeActions: {
              'right': Act.confirm(
                title: 'Delete Account',
                message:
                    'Delete this account? Transactions using it will remain.',
                onConfirm: Act.deleteEntry(),
              ),
            },
          ),
        ),
      ],
      fab: Actions.fab(
        icon: 'add',
        action: Act.navigate('add_account', params: {}),
      ),
    ),

    // ═══════════════════════════════════════════
    //  ADD ACCOUNT
    // ═══════════════════════════════════════════
    'add_account': Layout.formScreen(
      title: 'New Account',
      submitLabel: 'Save Account',
      defaults: {'icon': 'wallet', 'color': '#757575', 'sort_order': 99},
      mutations: {
        'create': Mut.sql(
          'INSERT INTO "m_fin_accounts" '
          '(id, name, icon, color, balance, sort_order, created_at, updated_at) '
          'VALUES (:id, :name, :icon, :color, COALESCE(:balance, 0), :sort_order, :created_at, :updated_at)',
        ),
      },
      children: [
        Inputs.textInput(
          fieldKey: 'name',
          label: 'Account Name',
          required: true,
          validation: {
            'required': true,
            'minLength': 1,
            'message': 'Give your account a name',
          },
        ),
        Inputs.colorPicker(
          fieldKey: 'color',
          label: 'Color',
        ),
        Inputs.currencyInput(
          fieldKey: 'balance',
          label: 'Initial Balance',
        ),
      ],
    ),

    // ═══════════════════════════════════════════
    //  EDIT ACCOUNT
    // ═══════════════════════════════════════════
    'edit_account': Layout.formScreen(
      title: 'Edit Account',
      editLabel: 'Update',
      mutations: {
        'update': Mut.sql(
          'UPDATE "m_fin_accounts" SET '
          'name = COALESCE(:name, name), '
          'color = COALESCE(:color, color), '
          'sort_order = COALESCE(:sort_order, sort_order), '
          'updated_at = :updated_at '
          'WHERE id = :id',
        ),
      },
      children: [
        Inputs.textInput(
          fieldKey: 'name',
          label: 'Account Name',
          required: true,
          validation: {
            'required': true,
            'minLength': 1,
            'message': 'Give your account a name',
          },
        ),
        Inputs.colorPicker(
          fieldKey: 'color',
          label: 'Color',
        ),
      ],
    ),

    // ═══════════════════════════════════════════
    //  ADD TAG
    // ═══════════════════════════════════════════
    'add_tag': Layout.formScreen(
      title: 'New Tag',
      submitLabel: 'Save Tag',
      queries: {
        'available_categories': Query.def(
          'SELECT id, name FROM "m_fin_categories" ORDER BY sort_order ASC',
        ),
      },
      mutations: {
        'create': Mut.sql(
          'INSERT INTO "m_fin_tags" '
          '(id, name, category_id, created_at, updated_at) '
          'VALUES (:id, :name, :category_id, :created_at, :updated_at)',
        ),
      },
      children: [
        Inputs.textInput(
          fieldKey: 'name',
          label: 'Tag Name',
          required: true,
          validation: {
            'required': true,
            'minLength': 1,
            'message': 'Give your tag a name',
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
      ],
    ),

    // ═══════════════════════════════════════════
    //  ADD RECURRING
    // ═══════════════════════════════════════════
    'add_recurring': Layout.formScreen(
      title: 'New Recurring',
      submitLabel: 'Save Recurring',
      defaults: {'type': 'expense', 'frequency': 'monthly', 'is_active': 1},
      queries: {
        'available_categories': Query.def(
          'SELECT id, name FROM "m_fin_categories" ORDER BY sort_order ASC',
        ),
        'available_accounts': Query.def(
          'SELECT id, name FROM "m_fin_accounts" ORDER BY sort_order ASC',
        ),
      },
      mutations: {
        'create': Mut.sql(
          'INSERT INTO "m_fin_recurring" '
          '(id, name, amount, type, merchant, category_id, account_id, frequency, next_date, is_active, note, created_at, updated_at) '
          'VALUES (:id, :name, :amount, :type, :merchant, :category_id, :account_id, :frequency, :next_date, 1, :note, :created_at, :updated_at)',
        ),
      },
      children: [
        Inputs.textInput(
          fieldKey: 'name',
          label: 'Name',
          required: true,
          validation: {
            'required': true,
            'minLength': 1,
            'message': 'Give it a name',
          },
        ),
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
        Inputs.enumSelector(
          fieldKey: 'type',
          label: 'Type',
          options: ['expense', 'income'],
        ),
        Inputs.textInput(
          fieldKey: 'merchant',
          label: 'Merchant',
        ),
        Inputs.referencePicker(
          fieldKey: 'category_id',
          schemaKey: 'category',
          displayField: 'name',
          source: 'available_categories',
          label: 'Category',
          emptyLabel: 'No categories yet',
          emptyAction: Act.navigate('add_category', params: {}),
        ),
        Inputs.referencePicker(
          fieldKey: 'account_id',
          schemaKey: 'account',
          displayField: 'name',
          source: 'available_accounts',
          label: 'Account',
          emptyLabel: 'No accounts yet',
          emptyAction: Act.navigate('add_account', params: {}),
        ),
        Inputs.enumSelector(
          fieldKey: 'frequency',
          label: 'Frequency',
          options: ['weekly', 'monthly', 'yearly'],
        ),
        Inputs.datePicker(
          fieldKey: 'next_date',
          label: 'Next Date',
        ),
        Inputs.textInput(
          fieldKey: 'note',
          label: 'Note',
          multiline: true,
        ),
      ],
    ),

    // ═══════════════════════════════════════════
    //  EDIT RECURRING
    // ═══════════════════════════════════════════
    'edit_recurring': Layout.formScreen(
      title: 'Edit Recurring',
      editLabel: 'Update',
      queries: {
        'available_categories': Query.def(
          'SELECT id, name FROM "m_fin_categories" ORDER BY sort_order ASC',
        ),
        'available_accounts': Query.def(
          'SELECT id, name FROM "m_fin_accounts" ORDER BY sort_order ASC',
        ),
      },
      mutations: {
        'update': Mut.sql(
          'UPDATE "m_fin_recurring" SET '
          'name = COALESCE(:name, name), '
          'amount = COALESCE(:amount, amount), '
          'type = COALESCE(:type, type), '
          'merchant = COALESCE(:merchant, merchant), '
          'category_id = COALESCE(:category_id, category_id), '
          'account_id = COALESCE(:account_id, account_id), '
          'frequency = COALESCE(:frequency, frequency), '
          'next_date = COALESCE(:next_date, next_date), '
          'note = COALESCE(:note, note), '
          'updated_at = :updated_at '
          'WHERE id = :id',
        ),
      },
      children: [
        Inputs.textInput(
          fieldKey: 'name',
          label: 'Name',
          required: true,
          validation: {
            'required': true,
            'minLength': 1,
            'message': 'Give it a name',
          },
        ),
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
        Inputs.enumSelector(
          fieldKey: 'type',
          label: 'Type',
          options: ['expense', 'income'],
        ),
        Inputs.textInput(
          fieldKey: 'merchant',
          label: 'Merchant',
        ),
        Inputs.referencePicker(
          fieldKey: 'category_id',
          schemaKey: 'category',
          displayField: 'name',
          source: 'available_categories',
          label: 'Category',
          emptyLabel: 'No categories yet',
          emptyAction: Act.navigate('add_category', params: {}),
        ),
        Inputs.referencePicker(
          fieldKey: 'account_id',
          schemaKey: 'account',
          displayField: 'name',
          source: 'available_accounts',
          label: 'Account',
          emptyLabel: 'No accounts yet',
          emptyAction: Act.navigate('add_account', params: {}),
        ),
        Inputs.enumSelector(
          fieldKey: 'frequency',
          label: 'Frequency',
          options: ['weekly', 'monthly', 'yearly'],
        ),
        Inputs.datePicker(
          fieldKey: 'next_date',
          label: 'Next Date',
        ),
        Inputs.textInput(
          fieldKey: 'note',
          label: 'Note',
          multiline: true,
        ),
      ],
    ),
  },
);
