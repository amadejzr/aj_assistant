/// SQL-driven Budget Tracker template.
///
/// Uses local SQLite tables instead of Firestore entries.
/// Accounts, expenses, and income are stored in module-owned tables.
/// Triggers handle balance updates automatically.
const budgetSqlTemplate = {
  'name': 'Budget (SQL)',
  'description': 'Track spending with local-first SQL tables and triggers.',
  'longDescription':
      'A budget tracker powered by local SQLite. Accounts, expenses, and '
      'income live in dedicated tables with triggers that automatically '
      'adjust balances. Fast, offline-first, no Firestore reads.',
  'icon': 'calculator',
  'color': '#2E7D32',
  'category': 'Finance',
  'tags': ['budget', 'expenses', 'income', 'accounts', 'sql'],
  'featured': false,
  'sortOrder': 10,
  'installCount': 0,
  'version': 1,
  'settings': {},
  'guide': [
    {
      'title': 'Getting Started',
      'body':
          'Create your bank accounts first, then start logging expenses '
          'and income. Balances update automatically via SQL triggers.',
    },
    {
      'title': 'How Triggers Work',
      'body':
          'When you add an expense, the account balance decreases. '
          'When you add income, it increases. Deleting reverses the change. '
          'All automatic — no manual balance updates needed.',
    },
  ],

  // ─── Navigation ───
  'navigation': {
    'bottomNav': {
      'items': [
        {'label': 'Home', 'icon': 'chart', 'screenId': 'main'},
        {'label': 'Expenses', 'icon': 'receipt', 'screenId': 'expenses'},
        {'label': 'Accounts', 'icon': 'wallet', 'screenId': 'accounts'},
      ],
    },
  },

  // ─── Database ───
  //
  // SQL tables owned by this module. SchemaManager runs setup[] on install.
  // Triggers auto-adjust account balances on expense/income changes.
  'database': {
    'tableNames': {
      'account': 'm_budget_sql_accounts',
      'expense': 'm_budget_sql_expenses',
      'income': 'm_budget_sql_income',
    },
    'setup': [
      // Accounts table
      '''CREATE TABLE IF NOT EXISTS "m_budget_sql_accounts" (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        account_type TEXT NOT NULL DEFAULT 'Checking',
        balance REAL NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )''',

      // Expenses table
      '''CREATE TABLE IF NOT EXISTS "m_budget_sql_expenses" (
        id TEXT PRIMARY KEY,
        amount REAL NOT NULL,
        description TEXT,
        category TEXT NOT NULL DEFAULT 'Other',
        account_id TEXT REFERENCES "m_budget_sql_accounts"(id),
        date INTEGER,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )''',

      // Income table
      '''CREATE TABLE IF NOT EXISTS "m_budget_sql_income" (
        id TEXT PRIMARY KEY,
        amount REAL NOT NULL,
        source TEXT,
        account_id TEXT REFERENCES "m_budget_sql_accounts"(id),
        date INTEGER,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )''',

      // Indexes
      'CREATE INDEX IF NOT EXISTS "idx_bsql_exp_account" ON "m_budget_sql_expenses" (account_id)',
      'CREATE INDEX IF NOT EXISTS "idx_bsql_exp_category" ON "m_budget_sql_expenses" (category)',
      'CREATE INDEX IF NOT EXISTS "idx_bsql_exp_date" ON "m_budget_sql_expenses" (date)',
      'CREATE INDEX IF NOT EXISTS "idx_bsql_inc_account" ON "m_budget_sql_income" (account_id)',
      'CREATE INDEX IF NOT EXISTS "idx_bsql_inc_date" ON "m_budget_sql_income" (date)',

      // Triggers: expense deducts from account balance
      '''CREATE TRIGGER IF NOT EXISTS "trg_bsql_expense_deduct"
        AFTER INSERT ON "m_budget_sql_expenses"
        FOR EACH ROW WHEN NEW.account_id IS NOT NULL BEGIN
          UPDATE "m_budget_sql_accounts"
          SET balance = balance - NEW.amount
          WHERE id = NEW.account_id;
        END''',

      '''CREATE TRIGGER IF NOT EXISTS "trg_bsql_expense_refund"
        AFTER DELETE ON "m_budget_sql_expenses"
        FOR EACH ROW WHEN OLD.account_id IS NOT NULL BEGIN
          UPDATE "m_budget_sql_accounts"
          SET balance = balance + OLD.amount
          WHERE id = OLD.account_id;
        END''',

      '''CREATE TRIGGER IF NOT EXISTS "trg_bsql_expense_adjust"
        AFTER UPDATE OF amount ON "m_budget_sql_expenses"
        FOR EACH ROW WHEN NEW.account_id IS NOT NULL BEGIN
          UPDATE "m_budget_sql_accounts"
          SET balance = balance - (NEW.amount - OLD.amount)
          WHERE id = NEW.account_id;
        END''',

      // Triggers: income adds to account balance
      '''CREATE TRIGGER IF NOT EXISTS "trg_bsql_income_add"
        AFTER INSERT ON "m_budget_sql_income"
        FOR EACH ROW WHEN NEW.account_id IS NOT NULL BEGIN
          UPDATE "m_budget_sql_accounts"
          SET balance = balance + NEW.amount
          WHERE id = NEW.account_id;
        END''',

      '''CREATE TRIGGER IF NOT EXISTS "trg_bsql_income_remove"
        AFTER DELETE ON "m_budget_sql_income"
        FOR EACH ROW WHEN OLD.account_id IS NOT NULL BEGIN
          UPDATE "m_budget_sql_accounts"
          SET balance = balance - OLD.amount
          WHERE id = OLD.account_id;
        END''',

      '''CREATE TRIGGER IF NOT EXISTS "trg_bsql_income_adjust"
        AFTER UPDATE OF amount ON "m_budget_sql_income"
        FOR EACH ROW WHEN NEW.account_id IS NOT NULL BEGIN
          UPDATE "m_budget_sql_accounts"
          SET balance = balance + (NEW.amount - OLD.amount)
          WHERE id = NEW.account_id;
        END''',
    ],
    'teardown': [
      'DROP TABLE IF EXISTS "m_budget_sql_expenses"',
      'DROP TABLE IF EXISTS "m_budget_sql_income"',
      'DROP TABLE IF EXISTS "m_budget_sql_accounts"',
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
        'title': 'Budget',
        'showBack': false,
      },
      'queries': {
        'total_balance': {
          'sql': 'SELECT COALESCE(SUM(balance), 0) as total FROM "m_budget_sql_accounts"',
        },
        'spent_total': {
          'sql': 'SELECT COALESCE(SUM(amount), 0) as total FROM "m_budget_sql_expenses"',
        },
        'earned_total': {
          'sql': 'SELECT COALESCE(SUM(amount), 0) as total FROM "m_budget_sql_income"',
        },
        'by_category': {
          'sql':
              'SELECT category, SUM(amount) as total '
              'FROM "m_budget_sql_expenses" '
              'GROUP BY category ORDER BY total DESC',
        },
        'recent_expenses': {
          'sql':
              'SELECT e.id, e.amount, e.description, e.category, '
              'a.name as account_name, e.date '
              'FROM "m_budget_sql_expenses" e '
              'LEFT JOIN "m_budget_sql_accounts" a ON e.account_id = a.id '
              'ORDER BY e.created_at DESC LIMIT 5',
        },
      },
      'children': [
        {
          'type': 'scroll_column',
          'children': [
            {
              'type': 'stat_card',
              'label': 'Total Balance',
              'stat': 'custom',
              'source': 'total_balance',
              'valueKey': 'total',
              'format': 'currency',
              'properties': {'accent': true, 'source': 'total_balance', 'valueKey': 'total'},
            },
            {
              'type': 'row',
              'children': [
                {
                  'type': 'stat_card',
                  'label': 'Total Spent',
                  'stat': 'custom',
                  'properties': {'source': 'spent_total', 'valueKey': 'total'},
                },
                {
                  'type': 'stat_card',
                  'label': 'Total Earned',
                  'stat': 'custom',
                  'properties': {'source': 'earned_total', 'valueKey': 'total'},
                },
              ],
            },
            {
              'type': 'chart',
              'chartType': 'donut',
              'source': 'by_category',
              'properties': {
                'source': 'by_category',
                'groupKey': 'category',
                'valueField': 'total',
              },
            },
            {
              'type': 'entry_list',
              'title': 'Recent Expenses',
              'viewAllScreen': 'all_expenses',
              'source': 'recent_expenses',
              'properties': {'source': 'recent_expenses'},
              'query': {},
              'itemLayout': {
                'type': 'entry_card',
                'title': '{{description}}',
                'subtitle': '{{category}} · {{account_name}}',
                'trailing': '{{amount}}',
                'trailingFormat': 'currency',
                'onTap': {
                  'type': 'navigate',
                  'screen': 'edit_expense',
                  'forwardFields': ['amount', 'description', 'category', 'account_id', 'date'],
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
          'screen': 'add_expense',
          'params': {},
        },
      },
    },

    // ═══════════════════════════════════════════
    //  EXPENSES — Full list with filters
    // ═══════════════════════════════════════════
    'expenses': {
      'type': 'screen',
      'appBar': {
        'type': 'app_bar',
        'title': 'Expenses',
        'showBack': false,
      },
      'queries': {
        'expenses': {
          'sql':
              'SELECT e.id, e.amount, e.description, e.category, '
              'a.name as account_name, e.date '
              'FROM "m_budget_sql_expenses" e '
              'LEFT JOIN "m_budget_sql_accounts" a ON e.account_id = a.id '
              'WHERE (:category = \'all\' OR e.category = :category) '
              'ORDER BY e.created_at DESC',
          'params': {'category': '{{filters.category}}'},
          'defaults': {'category': 'all'},
        },
        'category_total': {
          'sql':
              'SELECT COALESCE(SUM(amount), 0) as total '
              'FROM "m_budget_sql_expenses" '
              'WHERE (:category = \'all\' OR category = :category)',
          'params': {'category': '{{filters.category}}'},
          'defaults': {'category': 'all'},
        },
      },
      'mutations': {
        'delete': 'DELETE FROM "m_budget_sql_expenses" WHERE id = :id',
      },
      'children': [
        {
          'type': 'scroll_column',
          'children': [
            {
              'type': 'stat_card',
              'label': 'Total',
              'stat': 'custom',
              'properties': {'source': 'category_total', 'valueKey': 'total'},
            },
            {
              'type': 'entry_list',
              'source': 'expenses',
              'properties': {'source': 'expenses'},
              'query': {},
              'itemLayout': {
                'type': 'entry_card',
                'title': '{{description}}',
                'subtitle': '{{category}} · {{account_name}}',
                'trailing': '{{amount}}',
                'trailingFormat': 'currency',
                'onTap': {
                  'type': 'navigate',
                  'screen': 'edit_expense',
                  'forwardFields': ['amount', 'description', 'category', 'account_id', 'date'],
                  'params': {},
                },
                'swipeActions': {
                  'right': {
                    'type': 'confirm',
                    'title': 'Delete Expense',
                    'message': 'Delete this expense? Account balance will be restored.',
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
          'screen': 'add_expense',
          'params': {},
        },
      },
    },

    // ═══════════════════════════════════════════
    //  ACCOUNTS — List + balances
    // ═══════════════════════════════════════════
    'accounts': {
      'type': 'screen',
      'appBar': {
        'type': 'app_bar',
        'title': 'Accounts',
        'showBack': false,
      },
      'queries': {
        'accounts': {
          'sql':
              'SELECT id, name, account_type, balance '
              'FROM "m_budget_sql_accounts" ORDER BY name',
        },
        'total_balance': {
          'sql': 'SELECT COALESCE(SUM(balance), 0) as total FROM "m_budget_sql_accounts"',
        },
      },
      'mutations': {
        'delete': 'DELETE FROM "m_budget_sql_accounts" WHERE id = :id',
      },
      'children': [
        {
          'type': 'scroll_column',
          'children': [
            {
              'type': 'stat_card',
              'label': 'Total Balance',
              'stat': 'custom',
              'format': 'currency',
              'properties': {'accent': true, 'source': 'total_balance', 'valueKey': 'total'},
            },
            {
              'type': 'button',
              'label': 'Add Account',
              'style': 'outlined',
              'action': {
                'type': 'navigate',
                'screen': 'add_account',
                'params': {},
              },
            },
            {
              'type': 'entry_list',
              'source': 'accounts',
              'properties': {'source': 'accounts'},
              'query': {},
              'itemLayout': {
                'type': 'entry_card',
                'title': '{{name}}',
                'subtitle': '{{account_type}}',
                'trailing': '{{balance}}',
                'trailingFormat': 'currency',
                'onTap': {
                  'type': 'navigate',
                  'screen': 'edit_account',
                  'forwardFields': ['name', 'account_type', 'balance'],
                  'params': {},
                },
                'swipeActions': {
                  'right': {
                    'type': 'confirm',
                    'title': 'Delete Account',
                    'message': 'Delete this account? This cannot be undone.',
                    'onConfirm': {'type': 'delete_entry'},
                  },
                },
              },
            },
          ],
        },
      ],
    },

    // ═══════════════════════════════════════════
    //  ALL EXPENSES — Paginated with category filter
    // ═══════════════════════════════════════════
    'all_expenses': {
      'type': 'screen',
      'appBar': {
        'type': 'app_bar',
        'title': 'All Expenses',
      },
      'queries': {
        'expenses': {
          'sql':
              'SELECT e.id, e.amount, e.description, e.category, '
              'a.name as account_name, e.date '
              'FROM "m_budget_sql_expenses" e '
              'LEFT JOIN "m_budget_sql_accounts" a ON e.account_id = a.id '
              'ORDER BY e.created_at DESC',
        },
      },
      'mutations': {
        'delete': 'DELETE FROM "m_budget_sql_expenses" WHERE id = :id',
      },
      'children': [
        {
          'type': 'entry_list',
          'source': 'expenses',
          'properties': {'source': 'expenses'},
          'query': {},
          'itemLayout': {
            'type': 'entry_card',
            'title': '{{description}}',
            'subtitle': '{{category}} · {{account_name}}',
            'trailing': '{{amount}}',
            'trailingFormat': 'currency',
            'onTap': {
              'type': 'navigate',
              'screen': 'edit_expense',
              'forwardFields': ['amount', 'description', 'category', 'account_id', 'date'],
              'params': {},
            },
            'swipeActions': {
              'right': {
                'type': 'confirm',
                'title': 'Delete Expense',
                'message': 'Delete this expense?',
                'onConfirm': {'type': 'delete_entry'},
              },
            },
          },
        },
      ],
    },

    // ═══════════════════════════════════════════
    //  FORMS
    // ═══════════════════════════════════════════
    'add_expense': {
      'type': 'form_screen',
      'title': 'Add Expense',
      'submitLabel': 'Save',
      'mutations': {
        'create':
            'INSERT INTO "m_budget_sql_expenses" '
            '(id, amount, description, category, account_id, date, created_at, updated_at) '
            'VALUES (:id, :amount, :description, :category, :account_id, :date, :created_at, :updated_at)',
      },
      'children': [
        {'type': 'number_input', 'fieldKey': 'amount', 'label': 'Amount', 'required': true},
        {'type': 'text_input', 'fieldKey': 'description', 'label': 'What was it for?'},
        {'type': 'enum_selector', 'fieldKey': 'category', 'label': 'Category', 'required': true, 'options': ['Food', 'Transport', 'Housing', 'Entertainment', 'Health', 'Other']},
        {'type': 'date_picker', 'fieldKey': 'date', 'label': 'Date', 'required': true},
      ],
    },
    'edit_expense': {
      'type': 'form_screen',
      'title': 'Edit Expense',
      'editLabel': 'Update',
      'mutations': {
        'update':
            'UPDATE "m_budget_sql_expenses" SET '
            'amount = COALESCE(:amount, amount), '
            'description = COALESCE(:description, description), '
            'category = COALESCE(:category, category), '
            'account_id = COALESCE(:account_id, account_id), '
            'date = COALESCE(:date, date), '
            'updated_at = :updated_at '
            'WHERE id = :id',
      },
      'children': [
        {'type': 'number_input', 'fieldKey': 'amount', 'label': 'Amount', 'required': true},
        {'type': 'text_input', 'fieldKey': 'description', 'label': 'What was it for?'},
        {'type': 'enum_selector', 'fieldKey': 'category', 'label': 'Category', 'required': true, 'options': ['Food', 'Transport', 'Housing', 'Entertainment', 'Health', 'Other']},
        {'type': 'date_picker', 'fieldKey': 'date', 'label': 'Date', 'required': true},
      ],
    },
    'add_account': {
      'type': 'form_screen',
      'title': 'New Account',
      'submitLabel': 'Create',
      'mutations': {
        'create':
            'INSERT INTO "m_budget_sql_accounts" '
            '(id, name, account_type, balance, created_at, updated_at) '
            'VALUES (:id, :name, :account_type, :balance, :created_at, :updated_at)',
      },
      'defaults': {'balance': 0},
      'children': [
        {'type': 'text_input', 'fieldKey': 'name', 'label': 'Account Name', 'required': true},
        {'type': 'enum_selector', 'fieldKey': 'account_type', 'label': 'Type', 'required': true, 'options': ['Checking', 'Savings', 'Cash', 'Investment']},
        {'type': 'number_input', 'fieldKey': 'balance', 'label': 'Starting Balance', 'required': true},
      ],
    },
    'edit_account': {
      'type': 'form_screen',
      'title': 'Edit Account',
      'editLabel': 'Update',
      'mutations': {
        'update':
            'UPDATE "m_budget_sql_accounts" SET '
            'name = COALESCE(:name, name), '
            'account_type = COALESCE(:account_type, account_type), '
            'balance = COALESCE(:balance, balance), '
            'updated_at = :updated_at '
            'WHERE id = :id',
      },
      'children': [
        {'type': 'text_input', 'fieldKey': 'name', 'label': 'Account Name', 'required': true},
        {'type': 'enum_selector', 'fieldKey': 'account_type', 'label': 'Type', 'required': true, 'options': ['Checking', 'Savings', 'Cash', 'Investment']},
        {'type': 'number_input', 'fieldKey': 'balance', 'label': 'Starting Balance', 'required': true},
      ],
    },
    'add_income': {
      'type': 'form_screen',
      'title': 'Add Income',
      'submitLabel': 'Save',
      'mutations': {
        'create':
            'INSERT INTO "m_budget_sql_income" '
            '(id, amount, source, account_id, date, created_at, updated_at) '
            'VALUES (:id, :amount, :source, :account_id, :date, :created_at, :updated_at)',
      },
      'children': [
        {'type': 'number_input', 'fieldKey': 'amount', 'label': 'Amount', 'required': true},
        {'type': 'text_input', 'fieldKey': 'source', 'label': 'Source'},
        {'type': 'date_picker', 'fieldKey': 'date', 'label': 'Date', 'required': true},
      ],
    },
  },
};
