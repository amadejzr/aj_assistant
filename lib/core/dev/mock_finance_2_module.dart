import '../../features/schema/models/field_definition.dart';
import '../../features/schema/models/field_type.dart';
import '../../features/schema/models/module_schema.dart';
import '../models/module.dart';

Module createMockFinance2Module() {
  const accountFields = ['name', 'accountType', 'balance', 'institution'];
  const expenseFields = ['amount', 'category', 'account', 'note', 'date'];
  const incomeFields = ['amount', 'source', 'account', 'date'];
  const debtFields = ['name', 'balance', 'interestRate', 'minimumPayment'];
  const goalFields = ['name', 'target', 'saved', 'note'];

  return const Module(
    id: 'finance_2',
    name: 'Finance 2.0',
    description: 'Know your numbers. Build your future.',
    icon: 'wallet',
    color: '#2E7D32',
    sortOrder: 4,
    version: 2,
    settings: {
      'needsTarget': 50,
      'wantsTarget': 30,
      'savingsTarget': 20,
    },
    guide: [
      {'title': 'Getting Started', 'body': 'Add your bank accounts under the Accounts tab, then start logging expenses and income. Your net worth updates automatically.'},
      {'title': 'Budget Targets', 'body': 'The 50/30/20 rule splits income into Needs, Wants, and Savings. Tap "Adjust Budget Targets" on the Home tab to customize the percentages.'},
      {'title': 'Debt Tracking', 'body': 'Add credit cards and loans under Accounts → Debts. Track balances and interest rates to see your total liability alongside your assets.'},
      {'title': 'Savings Goals', 'body': 'Create goals in the Goals tab with a target amount. Update the "Saved So Far" field as you make progress — the progress bar fills automatically.'},
    ],
    schemas: {
      // ─── Accounts (checking, savings, investment, etc.) ───
      'account': ModuleSchema(
        label: 'Account',
        icon: 'wallet',
        fields: {
          'name': FieldDefinition(
            key: 'name',
            type: FieldType.text,
            label: 'Account Name',
            required: true,
          ),
          'accountType': FieldDefinition(
            key: 'accountType',
            type: FieldType.enumType,
            label: 'Type',
            required: true,
            options: [
              'Checking',
              'Savings',
              'Investment',
              'Retirement',
              'Cash',
            ],
          ),
          'balance': FieldDefinition(
            key: 'balance',
            type: FieldType.number,
            label: 'Balance',
            required: true,
          ),
          'institution': FieldDefinition(
            key: 'institution',
            type: FieldType.text,
            label: 'Bank / Institution',
          ),
        },
      ),

      // ─── Expenses ───
      'expense': ModuleSchema(
        label: 'Expense',
        icon: 'receipt',
        fields: {
          'amount': FieldDefinition(
            key: 'amount',
            type: FieldType.number,
            label: 'Amount',
            required: true,
          ),
          'category': FieldDefinition(
            key: 'category',
            type: FieldType.enumType,
            label: 'Category',
            required: true,
            options: ['Needs', 'Wants', 'Savings'],
          ),
          'account': FieldDefinition(
            key: 'account',
            type: FieldType.reference,
            label: 'From Account',
            constraints: {'schemaKey': 'account'},
          ),
          'note': FieldDefinition(
            key: 'note',
            type: FieldType.text,
            label: 'What was it for?',
          ),
          'date': FieldDefinition(
            key: 'date',
            type: FieldType.datetime,
            label: 'Date',
            required: true,
          ),
        },
      ),

      // ─── Income ───
      'income': ModuleSchema(
        label: 'Income',
        icon: 'cash',
        fields: {
          'amount': FieldDefinition(
            key: 'amount',
            type: FieldType.number,
            label: 'Amount',
            required: true,
          ),
          'source': FieldDefinition(
            key: 'source',
            type: FieldType.text,
            label: 'Source',
          ),
          'account': FieldDefinition(
            key: 'account',
            type: FieldType.reference,
            label: 'Deposit To',
            constraints: {'schemaKey': 'account'},
          ),
          'date': FieldDefinition(
            key: 'date',
            type: FieldType.datetime,
            label: 'Date',
            required: true,
          ),
        },
      ),

      // ─── Debts (credit cards, loans, etc.) ───
      'debt': ModuleSchema(
        label: 'Debt',
        icon: 'warning',
        fields: {
          'name': FieldDefinition(
            key: 'name',
            type: FieldType.text,
            label: 'Debt Name',
            required: true,
          ),
          'balance': FieldDefinition(
            key: 'balance',
            type: FieldType.number,
            label: 'Balance Owed',
            required: true,
          ),
          'interestRate': FieldDefinition(
            key: 'interestRate',
            type: FieldType.number,
            label: 'Interest Rate (%)',
          ),
          'minimumPayment': FieldDefinition(
            key: 'minimumPayment',
            type: FieldType.number,
            label: 'Minimum Payment',
          ),
        },
      ),

      // ─── Goals (emergency fund, house, travel, etc.) ───
      'goal': ModuleSchema(
        label: 'Goal',
        icon: 'target',
        fields: {
          'name': FieldDefinition(
            key: 'name',
            type: FieldType.text,
            label: 'Goal Name',
            required: true,
          ),
          'target': FieldDefinition(
            key: 'target',
            type: FieldType.number,
            label: 'Target Amount',
            required: true,
          ),
          'saved': FieldDefinition(
            key: 'saved',
            type: FieldType.number,
            label: 'Saved So Far',
            required: true,
          ),
          'note': FieldDefinition(
            key: 'note',
            type: FieldType.text,
            label: 'Note',
          ),
        },
      ),
    },

    screens: {
      // ═══════════════════════════════════════════
      //  MAIN — Four-tab layout
      // ═══════════════════════════════════════════
      'main': {
        'id': 'main',
        'type': 'tab_screen',
        'title': 'Finance',
        'tabs': [
          // ────────────── Tab 1: Home ──────────────
          // "What should I do with my money right now?"
          // One number, one insight area, one action.
          {
            'label': 'Home',
            'icon': 'chart',
            'content': {
              'type': 'scroll_column',
              'children': [
                // Net worth = assets - debts
                {
                  'type': 'stat_card',
                  'label': 'Net Worth',
                  'expression':
                      'subtract(sum(balance, where(schemaKey, ==, account)), sum(balance, where(schemaKey, ==, debt)))',
                  'format': 'currency',
                  'properties': {'accent': true},
                },

                // Key stats row
                {
                  'type': 'row',
                  'children': [
                    {
                      'type': 'stat_card',
                      'label': 'Income This Month',
                      'expression':
                          'sum(amount, period(month), where(schemaKey, ==, income))',
                      'format': 'currency',
                    },
                    {
                      'type': 'stat_card',
                      'label': 'Spent This Month',
                      'expression':
                          'sum(amount, period(month), where(schemaKey, ==, expense))',
                      'format': 'currency',
                    },
                  ],
                },

                // Total debt
                {
                  'type': 'row',
                  'children': [
                    {
                      'type': 'stat_card',
                      'label': 'Total Debt',
                      'expression':
                          'sum(balance, where(schemaKey, ==, debt))',
                      'format': 'currency',
                    },
                    {
                      'type': 'stat_card',
                      'label': 'Total Saved',
                      'expression':
                          'sum(saved, where(schemaKey, ==, goal))',
                      'format': 'currency',
                    },
                  ],
                },

                // Budget pulse — 50/30/20
                {
                  'type': 'section',
                  'title': 'Budget Pulse',
                  'children': [
                    {
                      'type': 'progress_bar',
                      'label': 'Needs',
                      'expression':
                          'percentage(sum(amount, period(month), where(category, ==, Needs), where(schemaKey, ==, expense)), multiply(sum(amount, period(month), where(schemaKey, ==, income)), divide(value(needsTarget), 100)))',
                      'format': 'percentage',
                    },
                    {
                      'type': 'progress_bar',
                      'label': 'Wants',
                      'expression':
                          'percentage(sum(amount, period(month), where(category, ==, Wants), where(schemaKey, ==, expense)), multiply(sum(amount, period(month), where(schemaKey, ==, income)), divide(value(wantsTarget), 100)))',
                      'format': 'percentage',
                    },
                    {
                      'type': 'progress_bar',
                      'label': 'Savings',
                      'expression':
                          'percentage(sum(amount, period(month), where(category, ==, Savings), where(schemaKey, ==, expense)), multiply(sum(amount, period(month), where(schemaKey, ==, income)), divide(value(savingsTarget), 100)))',
                      'format': 'percentage',
                    },
                  ],
                },

                // Adjust budget targets
                {
                  'type': 'button',
                  'label': 'Adjust Budget Targets',
                  'style': 'outlined',
                  'action': {
                    'type': 'navigate',
                    'screen': 'edit_budget',
                    'params': {'_settingsMode': true},
                  },
                },

                // Recent activity
                {
                  'type': 'section',
                  'title': 'Recent Spending',
                  'children': [
                    {
                      'type': 'entry_list',
                      'filter': [
                        {
                          'field': 'schemaKey',
                          'op': '==',
                          'value': 'expense',
                        },
                      ],
                      'query': {
                        'orderBy': 'date',
                        'direction': 'desc',
                        'limit': 3,
                      },
                      'itemLayout': {
                        'type': 'entry_card',
                        'title': '{{note}}',
                        'subtitle': '{{category}} · {{account}}',
                        'trailing': '{{amount}}',
                        'trailingFormat': 'currency',
                        'onTap': {
                          'type': 'navigate',
                          'screen': 'edit_expense',
                          'forwardFields': expenseFields,
                          'params': {'_schemaKey': 'expense'},
                        },
                      },
                    },
                  ],
                },
              ],
            },
          },

          // ────────────── Tab 2: Spending ──────────────
          // Full transaction log with category breakdown
          {
            'label': 'Spending',
            'icon': 'list',
            'content': {
              'type': 'scroll_column',
              'children': [
                // Category breakdown
                {
                  'type': 'row',
                  'children': [
                    {
                      'type': 'stat_card',
                      'label': 'Needs',
                      'expression':
                          'sum(amount, period(month), where(category, ==, Needs))',
                      'format': 'currency',
                      'filter': [
                        {
                          'field': 'schemaKey',
                          'op': '==',
                          'value': 'expense',
                        },
                      ],
                    },
                    {
                      'type': 'stat_card',
                      'label': 'Wants',
                      'expression':
                          'sum(amount, period(month), where(category, ==, Wants))',
                      'format': 'currency',
                      'filter': [
                        {
                          'field': 'schemaKey',
                          'op': '==',
                          'value': 'expense',
                        },
                      ],
                    },
                  ],
                },

                // Spending chart
                {
                  'type': 'chart',
                  'chartType': 'donut',
                  'groupBy': 'category',
                  'aggregate': 'sum',
                  'expression': 'group(category, sum(amount), period(month))',
                  'filter': [
                    {
                      'field': 'schemaKey',
                      'op': '==',
                      'value': 'expense',
                    },
                  ],
                },

                // Add buttons
                {
                  'type': 'row',
                  'children': [
                    {
                      'type': 'button',
                      'label': 'Add Expense',
                      'style': 'filled',
                      'action': {
                        'type': 'navigate',
                        'screen': 'add_expense',
                        'params': {'_schemaKey': 'expense'},
                      },
                    },
                    {
                      'type': 'button',
                      'label': 'Add Income',
                      'style': 'outlined',
                      'action': {
                        'type': 'navigate',
                        'screen': 'add_income',
                        'params': {'_schemaKey': 'income'},
                      },
                    },
                  ],
                },

                // Full expense log
                {
                  'type': 'section',
                  'title': 'All Expenses',
                  'children': [
                    {
                      'type': 'entry_list',
                      'filter': [
                        {
                          'field': 'schemaKey',
                          'op': '==',
                          'value': 'expense',
                        },
                      ],
                      'query': {
                        'orderBy': 'date',
                        'direction': 'desc',
                        'limit': 30,
                      },
                      'itemLayout': {
                        'type': 'entry_card',
                        'title': '{{note}}',
                        'subtitle': '{{category}} · {{account}}',
                        'trailing': '{{amount}}',
                        'trailingFormat': 'currency',
                        'onTap': {
                          'type': 'navigate',
                          'screen': 'edit_expense',
                          'forwardFields': expenseFields,
                          'params': {'_schemaKey': 'expense'},
                        },
                        'swipeActions': {
                          'right': {
                            'type': 'delete_entry',
                            'confirm': true,
                            'confirmMessage': 'Delete this expense?',
                          },
                        },
                      },
                    },
                  ],
                },

                // Income log
                {
                  'type': 'section',
                  'title': 'Income',
                  'children': [
                    {
                      'type': 'entry_list',
                      'filter': [
                        {
                          'field': 'schemaKey',
                          'op': '==',
                          'value': 'income',
                        },
                      ],
                      'query': {
                        'orderBy': 'date',
                        'direction': 'desc',
                        'limit': 10,
                      },
                      'itemLayout': {
                        'type': 'entry_card',
                        'title': '{{source}}',
                        'subtitle': '{{date}} · {{account}}',
                        'trailing': '{{amount}}',
                        'trailingFormat': 'currency',
                        'onTap': {
                          'type': 'navigate',
                          'screen': 'edit_income',
                          'forwardFields': incomeFields,
                          'params': {'_schemaKey': 'income'},
                        },
                        'swipeActions': {
                          'right': {
                            'type': 'delete_entry',
                            'confirm': true,
                            'confirmMessage': 'Delete this income entry?',
                          },
                        },
                      },
                    },
                  ],
                },
              ],
            },
          },

          // ────────────── Tab 3: Accounts ──────────────
          // Assets and debts — the net worth breakdown
          {
            'label': 'Accounts',
            'icon': 'wallet',
            'content': {
              'type': 'scroll_column',
              'children': [
                // Assets section
                {
                  'type': 'section',
                  'title': 'Assets',
                  'children': [
                    {
                      'type': 'stat_card',
                      'label': 'Total Assets',
                      'expression': 'sum(balance)',
                      'format': 'currency',
                      'filter': [
                        {
                          'field': 'schemaKey',
                          'op': '==',
                          'value': 'account',
                        },
                      ],
                    },
                    {
                      'type': 'button',
                      'label': 'Add Account',
                      'style': 'outlined',
                      'action': {
                        'type': 'navigate',
                        'screen': 'add_account',
                        'params': {'_schemaKey': 'account'},
                      },
                    },
                    {
                      'type': 'entry_list',
                      'filter': [
                        {
                          'field': 'schemaKey',
                          'op': '==',
                          'value': 'account',
                        },
                      ],
                      'query': {
                        'orderBy': 'name',
                        'direction': 'asc',
                      },
                      'itemLayout': {
                        'type': 'entry_card',
                        'title': '{{name}}',
                        'subtitle': '{{accountType}} · {{institution}}',
                        'trailing': '{{balance}}',
                        'trailingFormat': 'currency',
                        'onTap': {
                          'type': 'navigate',
                          'screen': 'edit_account',
                          'forwardFields': accountFields,
                          'params': {'_schemaKey': 'account'},
                        },
                        'swipeActions': {
                          'right': {
                            'type': 'delete_entry',
                            'confirm': true,
                            'confirmMessage': 'Delete this account?',
                          },
                        },
                      },
                    },
                  ],
                },

                // Debts section
                {
                  'type': 'section',
                  'title': 'Debts',
                  'children': [
                    {
                      'type': 'stat_card',
                      'label': 'Total Debt',
                      'expression': 'sum(balance)',
                      'format': 'currency',
                      'filter': [
                        {
                          'field': 'schemaKey',
                          'op': '==',
                          'value': 'debt',
                        },
                      ],
                    },
                    {
                      'type': 'button',
                      'label': 'Add Debt',
                      'style': 'outlined',
                      'action': {
                        'type': 'navigate',
                        'screen': 'add_debt',
                        'params': {'_schemaKey': 'debt'},
                      },
                    },
                    {
                      'type': 'entry_list',
                      'filter': [
                        {
                          'field': 'schemaKey',
                          'op': '==',
                          'value': 'debt',
                        },
                      ],
                      'query': {
                        'orderBy': 'balance',
                        'direction': 'desc',
                      },
                      'itemLayout': {
                        'type': 'entry_card',
                        'title': '{{name}}',
                        'subtitle': '{{interestRate}}% · min {{minimumPayment}}',
                        'trailing': '{{balance}}',
                        'trailingFormat': 'currency',
                        'onTap': {
                          'type': 'navigate',
                          'screen': 'edit_debt',
                          'forwardFields': debtFields,
                          'params': {'_schemaKey': 'debt'},
                        },
                        'swipeActions': {
                          'right': {
                            'type': 'delete_entry',
                            'confirm': true,
                            'confirmMessage': 'Delete this debt?',
                          },
                        },
                      },
                    },
                  ],
                },
              ],
            },
          },

          // ────────────── Tab 4: Goals ──────────────
          // Savings goals with progress tracking
          {
            'label': 'Goals',
            'icon': 'stats',
            'content': {
              'type': 'scroll_column',
              'children': [
                {
                  'type': 'row',
                  'children': [
                    {
                      'type': 'stat_card',
                      'label': 'Total Saved',
                      'expression': 'sum(saved)',
                      'format': 'currency',
                      'filter': [
                        {
                          'field': 'schemaKey',
                          'op': '==',
                          'value': 'goal',
                        },
                      ],
                    },
                    {
                      'type': 'stat_card',
                      'label': 'Total Target',
                      'expression': 'sum(target)',
                      'format': 'currency',
                      'filter': [
                        {
                          'field': 'schemaKey',
                          'op': '==',
                          'value': 'goal',
                        },
                      ],
                    },
                  ],
                },
                {
                  'type': 'progress_bar',
                  'label': 'Overall Goal Progress',
                  'expression': 'percentage(sum(saved), sum(target))',
                  'format': 'percentage',
                  'filter': [
                    {
                      'field': 'schemaKey',
                      'op': '==',
                      'value': 'goal',
                    },
                  ],
                },
                {
                  'type': 'button',
                  'label': 'Add Goal',
                  'style': 'outlined',
                  'action': {
                    'type': 'navigate',
                    'screen': 'add_goal',
                    'params': {'_schemaKey': 'goal'},
                  },
                },
                {
                  'type': 'entry_list',
                  'filter': [
                    {
                      'field': 'schemaKey',
                      'op': '==',
                      'value': 'goal',
                    },
                  ],
                  'query': {
                    'orderBy': 'name',
                    'direction': 'asc',
                  },
                  'itemLayout': {
                    'type': 'entry_card',
                    'title': '{{name}}',
                    'subtitle': '{{note}}',
                    'trailing': '{{saved}} / {{target}}',
                    'onTap': {
                      'type': 'navigate',
                      'screen': 'edit_goal',
                      'forwardFields': goalFields,
                      'params': {'_schemaKey': 'goal'},
                    },
                    'swipeActions': {
                      'right': {
                        'type': 'delete_entry',
                        'confirm': true,
                        'confirmMessage': 'Delete this goal?',
                      },
                    },
                  },
                },
              ],
            },
          },
        ],
        'fab': {
          'type': 'fab',
          'icon': 'add',
          'action': {
            'type': 'navigate',
            'screen': 'add_expense',
            'params': {'_schemaKey': 'expense'},
          },
        },
      },

      // ═══════════════════════════════════════════
      //  FORMS
      // ═══════════════════════════════════════════

      // ─── Budget targets (settings mode) ───
      'edit_budget': {
        'id': 'edit_budget',
        'type': 'form_screen',
        'title': 'Budget Targets',
        'submitLabel': 'Save',
        'children': [
          {
            'type': 'number_input',
            'fieldKey': 'needsTarget',
            'label': 'Needs (%)',
          },
          {
            'type': 'number_input',
            'fieldKey': 'wantsTarget',
            'label': 'Wants (%)',
          },
          {
            'type': 'number_input',
            'fieldKey': 'savingsTarget',
            'label': 'Savings (%)',
          },
        ],
      },

      // ─── Add expense ───
      'add_expense': {
        'id': 'add_expense',
        'type': 'form_screen',
        'title': 'Add Expense',
        'submitLabel': 'Save',
        'defaults': {},
        'onSubmit': [
          {
            'type': 'adjust_reference',
            'referenceField': 'account',
            'targetField': 'balance',
            'amountField': 'amount',
            'operation': 'subtract',
          },
        ],
        'children': [
          {'type': 'number_input', 'fieldKey': 'amount'},
          {
            'type': 'reference_picker',
            'fieldKey': 'account',
            'schemaKey': 'account',
            'displayField': 'name',
          },
          {'type': 'enum_selector', 'fieldKey': 'category'},
          {'type': 'text_input', 'fieldKey': 'note'},
          {'type': 'date_picker', 'fieldKey': 'date'},
        ],
      },

      // ─── Edit expense ───
      'edit_expense': {
        'id': 'edit_expense',
        'type': 'form_screen',
        'title': 'Edit Expense',
        'editLabel': 'Update',
        'children': [
          {'type': 'number_input', 'fieldKey': 'amount'},
          {
            'type': 'reference_picker',
            'fieldKey': 'account',
            'schemaKey': 'account',
            'displayField': 'name',
          },
          {'type': 'enum_selector', 'fieldKey': 'category'},
          {'type': 'text_input', 'fieldKey': 'note'},
          {'type': 'date_picker', 'fieldKey': 'date'},
        ],
      },

      // ─── Add income ───
      'add_income': {
        'id': 'add_income',
        'type': 'form_screen',
        'title': 'Add Income',
        'submitLabel': 'Save',
        'defaults': {},
        'onSubmit': [
          {
            'type': 'adjust_reference',
            'referenceField': 'account',
            'targetField': 'balance',
            'amountField': 'amount',
            'operation': 'add',
          },
        ],
        'children': [
          {'type': 'number_input', 'fieldKey': 'amount'},
          {'type': 'text_input', 'fieldKey': 'source'},
          {
            'type': 'reference_picker',
            'fieldKey': 'account',
            'schemaKey': 'account',
            'displayField': 'name',
          },
          {'type': 'date_picker', 'fieldKey': 'date'},
        ],
      },

      // ─── Edit income ───
      'edit_income': {
        'id': 'edit_income',
        'type': 'form_screen',
        'title': 'Edit Income',
        'editLabel': 'Update',
        'children': [
          {'type': 'number_input', 'fieldKey': 'amount'},
          {'type': 'text_input', 'fieldKey': 'source'},
          {
            'type': 'reference_picker',
            'fieldKey': 'account',
            'schemaKey': 'account',
            'displayField': 'name',
          },
          {'type': 'date_picker', 'fieldKey': 'date'},
        ],
      },

      // ─── Add account ───
      'add_account': {
        'id': 'add_account',
        'type': 'form_screen',
        'title': 'New Account',
        'submitLabel': 'Create',
        'defaults': {'balance': 0},
        'children': [
          {'type': 'text_input', 'fieldKey': 'name'},
          {'type': 'enum_selector', 'fieldKey': 'accountType'},
          {'type': 'number_input', 'fieldKey': 'balance'},
          {'type': 'text_input', 'fieldKey': 'institution'},
        ],
      },

      // ─── Edit account ───
      'edit_account': {
        'id': 'edit_account',
        'type': 'form_screen',
        'title': 'Edit Account',
        'editLabel': 'Update',
        'children': [
          {'type': 'text_input', 'fieldKey': 'name'},
          {'type': 'enum_selector', 'fieldKey': 'accountType'},
          {'type': 'number_input', 'fieldKey': 'balance'},
          {'type': 'text_input', 'fieldKey': 'institution'},
        ],
      },

      // ─── Add debt ───
      'add_debt': {
        'id': 'add_debt',
        'type': 'form_screen',
        'title': 'Add Debt',
        'submitLabel': 'Save',
        'defaults': {},
        'children': [
          {'type': 'text_input', 'fieldKey': 'name'},
          {'type': 'number_input', 'fieldKey': 'balance'},
          {'type': 'number_input', 'fieldKey': 'interestRate'},
          {'type': 'number_input', 'fieldKey': 'minimumPayment'},
        ],
      },

      // ─── Edit debt ───
      'edit_debt': {
        'id': 'edit_debt',
        'type': 'form_screen',
        'title': 'Edit Debt',
        'editLabel': 'Update',
        'children': [
          {'type': 'text_input', 'fieldKey': 'name'},
          {'type': 'number_input', 'fieldKey': 'balance'},
          {'type': 'number_input', 'fieldKey': 'interestRate'},
          {'type': 'number_input', 'fieldKey': 'minimumPayment'},
        ],
      },

      // ─── Add goal ───
      'add_goal': {
        'id': 'add_goal',
        'type': 'form_screen',
        'title': 'New Goal',
        'submitLabel': 'Create',
        'defaults': {'saved': 0},
        'children': [
          {'type': 'text_input', 'fieldKey': 'name'},
          {'type': 'number_input', 'fieldKey': 'target'},
          {'type': 'number_input', 'fieldKey': 'saved'},
          {'type': 'text_input', 'fieldKey': 'note'},
        ],
      },

      // ─── Edit goal ───
      'edit_goal': {
        'id': 'edit_goal',
        'type': 'form_screen',
        'title': 'Edit Goal',
        'editLabel': 'Update',
        'children': [
          {'type': 'text_input', 'fieldKey': 'name'},
          {'type': 'number_input', 'fieldKey': 'target'},
          {'type': 'number_input', 'fieldKey': 'saved'},
          {'type': 'text_input', 'fieldKey': 'note'},
        ],
      },
    },
  );
}
